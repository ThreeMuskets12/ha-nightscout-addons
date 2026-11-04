ARG MONGO_VERSION=7.0.45
FROM mongo:${MONGO_VERSION}
COPY run.sh /run.sh
RUN chmod 755 /run.sh
HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=3 \
  CMD ["bash", "-c", "exec 3<>/dev/tcp/127.0.0.1/27017"]
ENTRYPOINT ["/run.sh"]
CMD []
