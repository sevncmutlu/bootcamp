#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Building Release App Bundle (AAB) for Google Play..."
echo "========================================================"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/validate_frontend_release.sh"
cd "$(dirname "$0")/frontend"
flutter build appbundle --release "${MAKI_RELEASE_DEFINES[@]}"
echo "========================================================"
echo "Build complete. Output AAB location:"
echo "frontend/build/app/outputs/bundle/release/app-release.aab"
echo "========================================================"
