#!/usr/bin/env bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/frontend"

if [ ! -f "lib/core/database/database.g.dart" ]; then
    echo "Generating database code via build_runner..."
    dart run build_runner build
fi

echo "========================================================"
echo "Starting Flutter Web Server (Debug Mode)..."
echo "Open http://localhost:8080 in your browser"
echo "========================================================"
flutter run -d web-server --web-port 8080 \
  --dart-define=MAKI_ENV=preview \
  --dart-define=WEB_DEMO_MODE=true
