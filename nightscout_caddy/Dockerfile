ARG CADDY_VERSION=2.11
FROM caddy:${CADDY_VERSION}-builder AS builder
RUN xcaddy build --with github.com/caddy-dns/cloudflare
FROM caddy:${CADDY_VERSION}
RUN apk add --no-cache jq
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY run.sh /run.sh
RUN chmod 755 /run.sh
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD ["nc", "-z", "127.0.0.1", "443"]
ENTRYPOINT ["/run.sh"]
CMD []
