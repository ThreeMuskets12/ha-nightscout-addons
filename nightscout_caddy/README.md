# Nightscout HTTPS (Caddy)

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

Runs [Caddy][caddy], built with the [Cloudflare DNS plugin][plugin], as the HTTPS
front end for the **Nightscout** add-on. It gets a Let's Encrypt certificate over
the DNS-01 challenge, so no inbound access from the internet is needed, and
publishes host port 443.

See the [documentation](DOCS.md) for setup and options.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[caddy]: https://caddyserver.com
[plugin]: https://github.com/caddy-dns/cloudflare
