#!/usr/bin/env bash
set -euo pipefail
COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMAND_DIR/../.." && pwd)"
cd "$REPO_ROOT/frontend"
flutter build web --release \
  --dart-define=MAKI_ENV=preview \
  --dart-define=WEB_DEMO_MODE=true
echo "Web preview ready: frontend/build/web"
