#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Starting Flutter macOS Desktop App (Debug Mode)..."
echo "========================================================"
COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMAND_DIR/../.." && pwd)"
cd "$REPO_ROOT/frontend"
if [ ! -f "lib/core/database/database.g.dart" ]; then
    echo "Generating database code via build_runner..."
    dart run build_runner build
fi
flutter run -d macos --debug --dart-define=BACKEND_URL=http://localhost:8000
