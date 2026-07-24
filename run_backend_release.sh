#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Maki Backend (Production / Release Mode)..."
echo "========================================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ -f "$SCRIPT_DIR/.venv/bin/uv" ]; then
    "$SCRIPT_DIR/.venv/bin/uv" run --project backend uvicorn maki.bootstrap:create_runtime_app --factory --host 0.0.0.0 --port 8000 --workers 4
else
    export PYTHONPATH="$SCRIPT_DIR/.venv/lib/python3.12/site-packages:$SCRIPT_DIR/backend/src:$PYTHONPATH"
    "$SCRIPT_DIR/.venv/bin/python" -m uvicorn --app-dir backend/src maki.bootstrap:create_runtime_app --factory --host 0.0.0.0 --port 8000 --workers 4
fi
