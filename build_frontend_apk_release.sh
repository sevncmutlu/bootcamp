#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Building Release APK for Android..."
echo "========================================================"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/scripts/validate_frontend_release.sh"
cd "$(dirname "$0")/frontend"
flutter build apk --release "${MAKI_RELEASE_DEFINES[@]}"
echo "========================================================"
echo "Build complete. Output APK location:"
echo "frontend/build/app/outputs/flutter-apk/app-release.apk"
echo "========================================================"
