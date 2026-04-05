#!/bin/bash
set -euo pipefail

# Builds Papelim.app bundle from the Swift package

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_DIR="$BUILD_DIR/Papelim.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

CONFIG="${1:-release}"

echo "Building Papelim ($CONFIG)..."
cd "$PROJECT_DIR"
swift build -c "$CONFIG"

echo "Creating app bundle..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

# Copy binary
cp ".build/$CONFIG/Papelim" "$MACOS_DIR/Papelim"

# Copy Info.plist
cp "Papelim/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"

# Copy icon if it exists
if [ -f "Papelim/Resources/AppIcon.icns" ]; then
    cp "Papelim/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

# Copy Highlightr bundled resources (themes/grammars) alongside the binary,
# since SPM resource bundles live next to the executable in .build/ but must
# be included in the .app for syntax highlighting to work at runtime.
BUNDLE_NAME="Highlightr_Highlightr.bundle"
if [ -d ".build/$CONFIG/$BUNDLE_NAME" ]; then
    cp -R ".build/$CONFIG/$BUNDLE_NAME" "$MACOS_DIR/$BUNDLE_NAME"
fi

echo "Built: $APP_DIR"
