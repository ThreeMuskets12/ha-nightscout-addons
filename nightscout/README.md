# Nightscout

![Supports aarch64 Architecture][aarch64-shield]
![Supports amd64 Architecture][amd64-shield]

Runs the official [Nightscout cgm-remote-monitor][nightscout] image as a Home
Assistant add-on. It listens on port 1337 inside the add-on network only and
publishes no host ports.

It needs the **Nightscout MongoDB** add-on for storage, and the **Nightscout
HTTPS (Caddy)** add-on to be reachable from your network.

See the [documentation](DOCS.md) for setup and options.

[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg
[nightscout]: https://github.com/nightscout/cgm-remote-monitor
