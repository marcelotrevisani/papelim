#!/bin/bash
set -euo pipefail

# Generates AppIcon.icns from the SVG source.
# Requires librsvg: brew install librsvg

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SVG="$PROJECT_DIR/assets/papelim-icon.svg"
ICONSET="$PROJECT_DIR/build/AppIcon.iconset"
OUTPUT="$PROJECT_DIR/Papelim/Resources/AppIcon.icns"

if ! command -v rsvg-convert &>/dev/null; then
    echo "Error: rsvg-convert not found. Install with: brew install librsvg"
    exit 1
fi

echo "Generating icon from $SVG..."

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

for size in 16 32 64 128 256 512; do
    echo "  ${size}x${size}"
    rsvg-convert -w "$size" -h "$size" "$SVG" > "$ICONSET/icon_${size}x${size}.png"
    double=$((size * 2))
    rsvg-convert -w "$double" -h "$double" "$SVG" > "$ICONSET/icon_${size}x${size}@2x.png"
done

mkdir -p "$(dirname "$OUTPUT")"
iconutil -c icns "$ICONSET" -o "$OUTPUT"
rm -rf "$ICONSET"

echo "Created: $OUTPUT"
