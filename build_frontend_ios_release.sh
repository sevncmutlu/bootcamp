#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Building Release IPA / App Archive for iOS (macOS only)..."
echo "========================================================"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/validate_frontend_release.sh"
cd "$(dirname "$0")/frontend"
flutter build ipa --release "${MAKI_RELEASE_DEFINES[@]}"
echo "========================================================"
echo "Build complete. Output location:"
echo "frontend/build/ios/archive/"
echo "========================================================"
