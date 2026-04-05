#!/bin/bash
set -euo pipefail

# Builds a DMG containing Papelim.app with an Applications symlink

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/Papelim.app"
DMG_STAGING="$BUILD_DIR/dmg-staging"
VERSION="${1:-dev}"
DMG_NAME="Papelim-${VERSION}.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"

# Build the app first
"$SCRIPT_DIR/build-app.sh" release

echo "Creating DMG..."

# Prepare staging directory
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"
cp -R "$APP_DIR" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

# Create DMG
rm -f "$DMG_PATH"
hdiutil create \
    -volname "Papelim" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Cleanup staging
rm -rf "$DMG_STAGING"

echo "Created: $DMG_PATH"
echo "SHA256: $(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
