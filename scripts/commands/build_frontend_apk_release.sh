#!/usr/bin/env bash
set -e
echo "========================================================"
echo "Building Release APK for Android..."
echo "========================================================"
COMMAND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$COMMAND_DIR/../.." && pwd)"
source "$REPO_ROOT/scripts/validate_frontend_release.sh"
cd "$REPO_ROOT/frontend"
flutter build apk --release "${MAKI_RELEASE_DEFINES[@]}"
echo "========================================================"
echo "Build complete. Output APK location:"
echo "frontend/build/app/outputs/flutter-apk/app-release.apk"
echo "========================================================"
