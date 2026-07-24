#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Setting up ADB reverse tunnel for port 8000..."
echo "========================================================"
adb reverse tcp:8000 tcp:8000 2>/dev/null || true

echo "========================================================"
echo "Launching Flutter App on connected device (Debug)..."
echo "========================================================"
cd "$(dirname "$0")/frontend"
flutter run --debug --dart-define=BACKEND_URL=http://localhost:8000
