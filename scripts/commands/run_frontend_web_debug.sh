#!/usr/bin/env bash
set -e
COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMAND_DIR/../.." && pwd)"
cd "$REPO_ROOT/frontend"

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
