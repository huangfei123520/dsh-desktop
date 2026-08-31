#!/bin/bash
# Debug passthrough: docker run image <args> => exec args directly
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

set -e
export DSH_HOME="${DSH_HOME:-/data/dsh}"
mkdir -p "$DSH_HOME"
PORT="${DSH_PORT:-19090}"
echo "[dsh-desktop] DSH_HOME=$DSH_HOME dsh web on 127.0.0.1:$PORT, socat bridge 0.0.0.0:$PORT"

rm -f /tmp/dsh-web.log
nohup dsh web --port "$PORT" --no-open > /tmp/dsh-web.log 2>&1 &

# capture access token printed by dsh web and persist it for the NAS portal
TOK=""
for i in $(seq 1 30); do
  sleep 1
  TOK=$(grep -o 'token=[A-Za-z0-9_-]*' /tmp/dsh-web.log | head -1 | cut -d= -f2)
  if [ -n "$TOK" ]; then
    echo "$TOK" > /data/dsh/web-token
    chmod 644 /data/dsh/web-token
    echo "[dsh-desktop] captured web token -> /data/dsh/web-token"
    break
  fi
done
[ -z "$TOK" ] && echo "[dsh-desktop] WARN: token not captured yet"

# expose the loopback-bound web ui on all interfaces
exec socat TCP-LISTEN:"$PORT",fork,bind=0.0.0.0,reuseaddr TCP:127.0.0.1:"$PORT"
