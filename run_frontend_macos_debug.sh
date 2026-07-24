#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Flutter macOS Desktop App (Debug Mode)..."
echo "========================================================"
cd "$(dirname "$0")/frontend"
flutter run -d macos --debug --dart-define=BACKEND_URL=http://localhost:8000
