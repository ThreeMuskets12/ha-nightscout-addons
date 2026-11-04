# Nightscout Add-ons for Home Assistant

[![Builder](https://github.com/ThreeMuskets12/ha-nightscout-addons/actions/workflows/builder.yaml/badge.svg)](https://github.com/ThreeMuskets12/ha-nightscout-addons/actions/workflows/builder.yaml)
[![Lint](https://github.com/ThreeMuskets12/ha-nightscout-addons/actions/workflows/lint.yaml/badge.svg)](https://github.com/ThreeMuskets12/ha-nightscout-addons/actions/workflows/lint.yaml)

Run [Nightscout](https://github.com/nightscout/cgm-remote-monitor) on Home
Assistant OS or Supervised, with its database and HTTPS handled by add-ons.
Images are built for aarch64 and amd64.

| Add-on | Wraps | Purpose |
| --- | --- | --- |
| [Nightscout](nightscout) | `nightscout/cgm-remote-monitor` | The Nightscout web app and API |
| [Nightscout MongoDB](nightscout_mongodb) | `mongo` 7.0 | Database |
| [Nightscout HTTPS (Caddy)](nightscout_caddy) | `caddy` with the Cloudflare DNS plugin | HTTPS reverse proxy |

## Install

1. In Home Assistant, go to **Settings > Add-ons > Add-on Store**.
2. Open the menu in the top right and choose **Repositories**.
3. Add `https://github.com/ThreeMuskets12/ha-nightscout-addons` exactly as
   written. The default add-on hostnames depend on this URL.
4. Install all three add-ons.
5. Configure and start them in this order, following each add-on's
   Documentation tab:
   1. **Nightscout MongoDB**: set `root_password`.
   2. **Nightscout**: set `api_secret`, `mongo_password` (the same value as
      `root_password`) and `base_url`, for example
      `https://nightscout.example.com`.
   3. **Nightscout HTTPS (Caddy)**: set `domain`, for example
      `nightscout.example.com`, and `cf_dns_token`.

All secrets default to empty, and each add-on refuses to start until the values
it needs are set.

## Architecture

```text
 client ──HTTPS :443──▶ Caddy ──HTTP :1337──▶ Nightscout ──:27017──▶ MongoDB
                        │                     └─────── add-on network only ───┘
                        └── DNS-01 via Cloudflare ──▶ Let's Encrypt
```

- **Caddy** is the only add-on with a host port (443/tcp). It terminates TLS and
  forwards to Nightscout. It gets certificates over DNS-01, so no port has to be
  opened to the internet.
- **Nightscout** listens on port 1337 on the internal add-on network, with no
  host ports.
- **MongoDB** listens on port 27017 on the internal add-on network, with no host
  ports. Its data is stored in the add-on's `/data` directory.

## Security notes

- `api_secret` must be at least 12 characters, and the Nightscout add-on will not
  start otherwise. It grants full access to your data, so use a long random
  value.
- `auth_default_roles` controls what visitors can do without authenticating:
  - `readable` (default): read is public, write needs authentication. Anyone who
    can reach the site can see glucose data.
  - `denied`: read and write both need authentication. Use access tokens from
    Nightscout's Admin Tools for followers and devices.
- Scope the Cloudflare token to `Zone / DNS / Edit` on one zone.
- Options are stored unencrypted in Home Assistant, and are included in its
  backups. Protect your backups accordingly.
- Before exposing Nightscout to the internet, set `auth_default_roles` to
  `denied` unless you want your data to be public.

## Upgrades

Updates appear in Home Assistant as normal add-on updates. A daily workflow
proposes upstream version bumps as pull requests.

**MongoDB major upgrades need a manual migration.** The add-on deliberately stays
on 7.0, and automated updates only follow 7.0.x patch releases. MongoDB can only
step through one major version at a time, and data files are not downgraded
automatically, so changing major version means taking a backup (for example with
`mongodump`) and following MongoDB's upgrade guide, or restoring the dump into a
fresh data directory. Do not edit the version and rebuild without doing this.

## Development

- Each add-on's base image version is set by an `ARG` in its `Dockerfile`, with
  the same version in `build.yaml`.
- Pushes to `main` build and publish the changed add-ons to GHCR. Tags and manual
  runs build all of them. Pull requests build without publishing.
- The published tag comes from `version` in `config.yaml`, so bump it for any
  change users should receive.
- `UPDATE_TOKEN` is an optional repository secret holding a personal access
  token for the update workflow. Without it, pull requests from that workflow
  do not trigger the Builder and Lint checks, because GitHub does not start
  workflows from events created with `GITHUB_TOKEN`.

## License

[MIT](LICENSE)
