#!/bin/bash
# Debug passthrough: docker run image <args> => exec args directly
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

set -e
export DSH_HOME="${DSH_HOME:-/data/dsh}"
mkdir -p "$DSH_HOME"
PORT="${DSH_PORT:-19090}"
echo "[dsh-desktop] DSH_HOME=$DSH_HOME starting web ui on port $PORT"

# Prefer explicit external binding; fall back if --host unsupported by this dsh version.
if dsh web --host 0.0.0.0 --port "$PORT" --no-open 2>/dev/null; then
  exit 0
fi
echo "[dsh-desktop] --host/--no-open rejected, retrying with defaults"
exec dsh web --port "$PORT" --no-open || exec dsh web --port "$PORT"
