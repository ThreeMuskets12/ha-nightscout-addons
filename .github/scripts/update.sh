#!/usr/bin/env bash
# Bumps each add-on to its latest upstream version: Dockerfile, build.yaml,
# config.yaml version and CHANGELOG.md. A failed upstream check does not stop
# the others, it is reported through the "failed" output.
#
# Writes "summary" and "failed" to $GITHUB_OUTPUT when that is set.
# Optional: GITHUB_TOKEN (avoids API rate limits), REPO_ROOT (for testing).

set -euo pipefail

REPO_ROOT=${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}
REQUIRED_ARCHES='["amd64","arm64"]'
HUB_API=https://hub.docker.com/v2/repositories
MAX_HUB_PAGES=30
VERSION_RE='^[0-9]+(\.[0-9]+)+$'

failed=false
summary=""

log() { echo "$*" >&2; }

fetch() {
  curl --fail --silent --show-error --location --retry 3 --retry-delay 5 --max-time 30 "$@"
}

latest_github_release() {
  local repo=$1 args=(-H "Accept: application/vnd.github+json") tag
  if [ -n "${GITHUB_TOKEN:-}" ]; then
    args+=(-H "Authorization: Bearer $GITHUB_TOKEN")
  fi
  tag=$(fetch "${args[@]}" "https://api.github.com/repos/$repo/releases/latest" | jq -r '.tag_name // empty') || return 1
  [ -n "$tag" ] || return 1
  echo "${tag#v}"
}

latest_mongo_7_0() {
  local url="$HUB_API/library/mongo/tags?name=7.0.&page_size=100" page=0 body tags=""
  while [ -n "$url" ]; do
    page=$((page + 1))
    if [ "$page" -gt "$MAX_HUB_PAGES" ]; then
      log "Too many Docker Hub tag pages"
      return 1
    fi
    body=$(fetch "$url") || return 1
    tags+=$(jq -r '.results[].name' <<<"$body")$'\n' || return 1
    url=$(jq -r '.next // empty' <<<"$body") || return 1
  done
  tags=$(grep -E '^7\.0\.[0-9]+$' <<<"$tags" | sort -V | tail -n 1) || return 1
  [ -n "$tags" ] || return 1
  echo "$tags"
}

# Upstream often tags a release before its images are published
docker_tag_ready() {
  local repo=$1 tag=$2
  fetch "$HUB_API/$repo/tags/$tag" 2>/dev/null \
    | jq -e --argjson required "$REQUIRED_ARCHES" \
      '[.images[].architecture] as $have | $required - $have | length == 0' >/dev/null
}

version_gt() {
  [ "$1" != "$2" ] && [ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n 1)" = "$1" ]
}

# X.Y.Z bumps Z. <upstream>-N restarts at <new upstream>-1, and any other -N bumps N.
next_addon_version() {
  local current=$1 old=$2 new=$3
  if [[ $current == "$old"-* && ${current#"$old"-} =~ ^[0-9]+$ ]]; then
    echo "$new-1"
  elif [[ $current =~ ^([0-9]+\.[0-9]+\.)([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}$((BASH_REMATCH[2] + 1))"
  elif [[ $current =~ ^(.*-)([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}$((BASH_REMATCH[2] + 1))"
  else
    log "Cannot bump add-on version '$current'"
    return 1
  fi
}

prepend_changelog() {
  local file=$1 version=$2 entry=$3 tmp
  tmp=$(mktemp)
  {
    head -n 1 "$file"
    printf '\n## %s\n\n- %s\n' "$version" "$entry"
    tail -n +2 "$file"
  } >"$tmp"
  cat "$tmp" >"$file"
  rm -f "$tmp"
}

apply_update() {
  local addon=$1 arg=$2 old=$3 new=$4 label=$5
  local dir="$REPO_ROOT/$addon" current next entry
  current=$(sed -nE 's/^version: *"?([^"]+)"?$/\1/p' "$dir/config.yaml")
  next=$(next_addon_version "$current" "$old" "$new") || return 1
  entry="Update $label to $new"
  sed -i -E "s/^ARG $arg=.*/ARG $arg=$new/" "$dir/Dockerfile"
  sed -i -E "s/:${old//./\\.}\$/:$new/" "$dir/build.yaml"
  sed -i -E "s/^version: .*/version: \"$next\"/" "$dir/config.yaml"
  prepend_changelog "$dir/CHANGELOG.md" "$next" "$entry"
  summary+="- \`$addon\` $current -> $next: $label $old -> $new"$'\n'
}

# Prints the version to move to, or nothing when the add-on is up to date
check_version() {
  local name=$1 addon=$2 arg=$3 latest=$4 current
  current=$(sed -nE "s/^ARG $arg=(.*)\$/\1/p" "$REPO_ROOT/$addon/Dockerfile")
  if ! [[ $current =~ $VERSION_RE ]]; then
    log "$name: cannot read current version from $addon/Dockerfile"
    return 1
  fi
  if ! [[ $latest =~ $VERSION_RE ]]; then
    log "$name: unexpected upstream version '$latest'"
    return 1
  fi
  if ! version_gt "$latest" "$current"; then
    log "$name: $current is up to date (latest $latest)"
    return 0
  fi
  echo "$current $latest"
}

update_nightscout() {
  local latest versions
  latest=$(latest_github_release nightscout/cgm-remote-monitor) || return 1
  versions=$(check_version Nightscout nightscout NIGHTSCOUT_VERSION "$latest") || return 1
  [ -n "$versions" ] || return 0
  if ! docker_tag_ready nightscout/cgm-remote-monitor "$latest"; then
    log "Nightscout: image $latest is not published yet, trying again next run"
    return 0
  fi
  # shellcheck disable=SC2086 # versions is "old new"
  apply_update nightscout NIGHTSCOUT_VERSION $versions "Nightscout"
}

update_mongo() {
  local latest versions
  latest=$(latest_mongo_7_0) || return 1
  versions=$(check_version MongoDB nightscout_mongodb MONGO_VERSION "$latest") || return 1
  [ -n "$versions" ] || return 0
  if ! docker_tag_ready library/mongo "$latest"; then
    log "MongoDB: image $latest is not published yet, trying again next run"
    return 0
  fi
  # shellcheck disable=SC2086 # versions is "old new"
  apply_update nightscout_mongodb MONGO_VERSION $versions "MongoDB"
}

update_caddy() {
  local latest versions
  latest=$(latest_github_release caddyserver/caddy) || return 1
  versions=$(check_version Caddy nightscout_caddy CADDY_VERSION "$latest") || return 1
  [ -n "$versions" ] || return 0
  if ! docker_tag_ready library/caddy "$latest" || ! docker_tag_ready library/caddy "$latest-builder"; then
    log "Caddy: images for $latest are not published yet, trying again next run"
    return 0
  fi
  # shellcheck disable=SC2086 # versions is "old new"
  apply_update nightscout_caddy CADDY_VERSION $versions "Caddy"
}

for update in update_nightscout update_mongo update_caddy; do
  if ! "$update"; then
    log "::warning::$update failed"
    failed=true
  fi
done

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "failed=$failed"
    echo "summary<<SUMMARY_EOF"
    echo "${summary:-No updates.}"
    echo "SUMMARY_EOF"
  } >>"$GITHUB_OUTPUT"
fi
log "${summary:-No updates.}"
