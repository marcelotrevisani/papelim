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

# Copy all SPM resource bundles.
# SPM's generated Bundle.module accessor looks at:
#   Bundle.main.bundleURL / <name>.bundle
# For a .app, Bundle.main.bundleURL is the .app directory itself, so bundles
# must live at the TOP level of the .app (next to Contents/).
for bundle in .build/"$CONFIG"/*.bundle; do
    [ -d "$bundle" ] || continue
    cp -R "$bundle" "$APP_DIR/"
    echo "  Bundled: $(basename "$bundle")"
done

echo "Built: $APP_DIR"
