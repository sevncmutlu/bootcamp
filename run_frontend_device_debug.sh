#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Setting up ADB reverse tunnel for port 8000..."
echo "========================================================"
adb reverse tcp:8000 tcp:8000 2>/dev/null || true

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

if [ ! -f "lib/core/database/database.g.dart" ]; then
    echo "Generating database code via build_runner..."
    dart run build_runner build
fi

echo "========================================================"
echo "Launching Flutter App on connected device (Debug)..."
echo "========================================================"
flutter run --debug --dart-define=BACKEND_URL=http://localhost:8000
