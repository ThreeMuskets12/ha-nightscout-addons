ARG NIGHTSCOUT_VERSION=15.0.9
FROM nightscout/cgm-remote-monitor:${NIGHTSCOUT_VERSION}
USER root
COPY run.js /run.js
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD ["node", "-e", "require('net').connect(1337, '127.0.0.1').on('connect', () => process.exit(0)).on('error', () => process.exit(1))"]
ENTRYPOINT ["node", "/run.js"]
CMD []
