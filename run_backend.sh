#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Maki Backend (Development / Debug Mode)..."
echo "========================================================"
cd "$(dirname "$0")/backend"
uv run uvicorn maki.api.main:app --reload --port 8000
