#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Flutter Web Server (Debug Mode)..."
echo "Open http://localhost:8080 in your browser"
echo "========================================================"
cd "$(dirname "$0")/frontend"
flutter run -d web-server --web-port 8080 --dart-define=BACKEND_URL=http://localhost:8000
