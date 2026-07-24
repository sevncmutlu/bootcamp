#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Maki Backend (Production / Release Mode)..."
echo "========================================================"
cd "$(dirname "$0")/backend"
uv run uvicorn maki.api.main:app --host 0.0.0.0 --port 8000 --workers 4
