# Nightscout HTTPS (Caddy)

## Setup

1. Keep your domain's DNS zone on Cloudflare.
2. Create a Cloudflare API token with `Zone / DNS / Edit` permission, limited to
   that zone.
3. Point `nightscout.example.com` at your Home Assistant host. This can be a
   private address if you only use Nightscout on your own network.
4. Set `domain` and `cf_dns_token` below and start the add-on.
5. Open `https://nightscout.example.com`.

The add-on stops at startup with an error in its log if `domain` or
`cf_dns_token` is empty, or if `domain` or `upstream` contains anything other
than plain host and port characters.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `domain` | empty | Hostname to serve, for example `nightscout.example.com`. Required. |
| `upstream` | `2e288520-nightscout:1337` | Nightscout add-on host and port. See below. |
| `cf_dns_token` | empty | Cloudflare API token. Required. |

### `upstream`

The default works when this repository was added using its exact URL,
`https://github.com/ThreeMuskets12/ha-nightscout-addons`. Home Assistant derives
the `2e288520` prefix from that URL, so a fork or a local copy gets a different
one (`local-nightscout:1337` for a local add-on). The correct hostname is shown
as **Hostname** on the Nightscout add-on's Info page.

## Network

Only HTTPS on port 443/tcp is served, and there is no redirect from port 80.
Certificates are stored in the add-on's `/data` directory and renew
automatically.
