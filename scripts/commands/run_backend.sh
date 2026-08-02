#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Maki Backend (Development / Debug Mode)..."
echo "========================================================"

COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMAND_DIR/../.." && pwd)"
cd "$REPO_ROOT"

if [ -f "$REPO_ROOT/.venv/bin/uv" ]; then
    "$REPO_ROOT/.venv/bin/uv" run --project backend uvicorn maki.bootstrap:create_runtime_app --factory --reload --port 8000
else
    export PYTHONPATH="$REPO_ROOT/.venv/lib/python3.12/site-packages:$REPO_ROOT/backend/src:$PYTHONPATH"
    "$REPO_ROOT/.venv/bin/python" -m uvicorn --app-dir backend/src maki.bootstrap:create_runtime_app --factory --reload --port 8000
fi
