#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Building Release IPA / App Archive for iOS (macOS only)..."
echo "========================================================"
COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMAND_DIR/../.." && pwd)"
source "$REPO_ROOT/scripts/validate_frontend_release.sh"
cd "$REPO_ROOT/frontend"
flutter build ipa --release "${MAKI_RELEASE_DEFINES[@]}"
echo "========================================================"
echo "Build complete. Output location:"
echo "frontend/build/ios/archive/"
echo "========================================================"
