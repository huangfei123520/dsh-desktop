FROM node:22-bookworm-slim

RUN apt-get update  && apt-get install -y --no-install-recommends ca-certificates curl git socat  && rm -rf /var/lib/apt/lists/*  && npm install -g @deepseek-ai/dsh@0.1.2-alpha.2  && npm cache clean --force

ENV DSH_HOME=/data/dsh     DSH_PORT=19090

COPY start.sh /usr/local/bin/dsh-entrypoint.sh
RUN chmod +x /usr/local/bin/dsh-entrypoint.sh && mkdir -p /data/dsh

VOLUME ["/data/dsh"]
EXPOSE 19090

ENTRYPOINT ["/usr/local/bin/dsh-entrypoint.sh"]
