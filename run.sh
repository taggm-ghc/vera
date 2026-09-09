#!/usr/bin/env bash
# Start the VERA FastAPI service locally with autoreload.
#
# Usage:
#   ./run.sh            # serve on port 8001
#   ./run.sh 8000       # serve on a different port
#   PORT=8080 ./run.sh  # or via env var

set -euo pipefail

cd "$(dirname "$0")"

PORT="${1:-${PORT:-8001}}"
HOST="${HOST:-127.0.0.1}"

# Pre-flight: bail out if something is already listening on the target port.
if (exec 3<>"/dev/tcp/${HOST}/${PORT}") 2>/dev/null; then
    exec 3>&- 3<&-
    if curl -sf -m 2 "http://${HOST}:${PORT}/health" >/dev/null 2>&1; then
        echo "VERA already appears to be running at http://${HOST}:${PORT}/health"
    else
        echo "Error: port ${PORT} on ${HOST} is already in use by another process." >&2
        echo "Pick another port (./run.sh <port>) or free it, e.g.:" >&2
        echo "  pkill -f 'uvicorn main:app'" >&2
    fi
    exit 1
fi

# Activate the project virtualenv if it exists and isn't already active.
if [[ -z "${VIRTUAL_ENV:-}" && -f .venv/bin/activate ]]; then
    # shellcheck disable=SC1091
    source .venv/bin/activate
fi

echo "Starting uvicorn on http://${HOST}:${PORT}"
echo "  health check: http://${HOST}:${PORT}/health"
echo "  API docs:     http://${HOST}:${PORT}/docs"

exec uvicorn main:app --reload --host "$HOST" --port "$PORT"
