#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Building Release IPA / App Archive for iOS (macOS only)..."
echo "========================================================"
cd "$(dirname "$0")/frontend"
flutter build ipa --release --dart-define=BACKEND_URL=http://localhost:8000
echo "========================================================"
echo "Build complete. Output location:"
echo "frontend/build/ios/archive/"
echo "========================================================"
