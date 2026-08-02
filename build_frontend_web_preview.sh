#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/frontend"
flutter build web --release \
  --dart-define=MAKI_ENV=preview \
  --dart-define=WEB_DEMO_MODE=true
echo "Web preview ready: frontend/build/web"
