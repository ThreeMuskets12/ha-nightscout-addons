#!/bin/sh
set -e
CF_API_TOKEN=$(jq -r '.cf_dns_token // empty' /data/options.json)
D=$(jq -r '.domain // empty' /data/options.json); U=$(jq -r '.upstream // empty' /data/options.json)
[ -n "$CF_API_TOKEN" ] || { echo "cf_dns_token not set"; exit 1; }
# both values end up in the Caddyfile, so only allow plain host[:port] characters
case "$D" in ""|*[!A-Za-z0-9.-]*) echo "domain missing or invalid"; exit 1;; esac
case "$U" in ""|*[!A-Za-z0-9.:_-]*) echo "upstream missing or invalid"; exit 1;; esac
export CF_API_TOKEN XDG_DATA_HOME=/data XDG_CONFIG_HOME=/data/config
cat > /etc/caddy/Caddyfile <<CF
{
	auto_https disable_redirects
	admin off
}
$D {
	tls {
		dns cloudflare {env.CF_API_TOKEN}
		resolvers 1.1.1.1
	}
	reverse_proxy $U
}
CF
exec caddy run --config /etc/caddy/Caddyfile --adapter caddyfile
