# Nightscout

## Setup

1. Install and start the **Nightscout MongoDB** add-on first.
2. Set `api_secret`, `mongo_password` and `base_url` below.
3. Start this add-on, then install **Nightscout HTTPS (Caddy)** to reach it.

The add-on stops at startup with an error in its log if `api_secret` is shorter
than 12 characters or `mongo_password` is empty.

## Options

| Option | Default | Description |
| --- | --- | --- |
| `api_secret` | empty | Nightscout API secret. Required, at least 12 characters. |
| `mongo_password` | empty | Must match `root_password` of the MongoDB add-on. Required. |
| `mongo_host` | `2e288520-nightscout-mongodb` | Hostname of the MongoDB add-on. See below. |
| `base_url` | empty | Public URL, for example `https://nightscout.example.com`. |
| `auth_default_roles` | `readable` | Role given to unauthenticated visitors. See below. |
| `display_units` | `mg/dl` | `mg/dl` or `mmol`. |
| `enable` | see add-on | Space-separated list of enabled plugins. |
| `show_plugins` | see add-on | Space-separated list of plugins shown by default. |
| `custom_title` | `Nightscout` | Site title. |

The timezone comes from your Home Assistant system settings.

### `mongo_host`

The default works when this repository was added using its exact URL,
`https://github.com/ThreeMuskets12/ha-nightscout-addons`. Home Assistant derives
the `2e288520` prefix from that URL, so a fork or a local copy gets a different
one (`local-nightscout-mongodb` for a local add-on). The correct value is shown
as **Hostname** on the MongoDB add-on's Info page.

### `auth_default_roles`

- `readable`: anyone who can reach the site can read glucose data. Writes need
  the API secret or an access token.
- `denied`: reading also needs the API secret or an access token. Create tokens
  for followers and devices in Nightscout's Admin Tools.

## Network

Nightscout trusts `X-Forwarded-For` only from the add-on network, which is how
it sees real client addresses through Caddy. TLS is terminated by Caddy, so
Nightscout itself speaks plain HTTP inside that network.
