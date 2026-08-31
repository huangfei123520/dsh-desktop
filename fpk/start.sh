#!/bin/bash
set -e
export DSH_HOME="${DSH_HOME:-/data/dsh}"
mkdir -p "$DSH_HOME"
echo "[dsh-desktop] DSH_HOME=$DSH_HOME starting web ui on port ${DSH_PORT:-19090}"
exec dsh web --port "${DSH_PORT:-19090}"
