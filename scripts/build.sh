#!/usr/bin/env bash
# Build MarkdownViewer.app from the SwiftPM package — no Xcode required.
#
# Steps: compile (release) → generate icon → assemble the .app bundle →
# copy resource bundles next to the executable → ad-hoc code-sign.
set -euo pipefail

cd "$(dirname "$0")/.."          # project root (mac-app/)

APP_NAME="Markdown Viewer — madebytle.com"
EXECUTABLE="MarkdownViewer"
BUNDLE_ID="com.madebytle.markdown-viewer"
DIST="dist"
APP="$DIST/$APP_NAME.app"
BUILD_CONFIG="release"

echo "==> swift build ($BUILD_CONFIG)"
swift build -c "$BUILD_CONFIG"

BIN_DIR="$(swift build -c "$BUILD_CONFIG" --show-bin-path)"

echo "==> Generating app icon"
ICONSET="$DIST/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
swift scripts/make-icon.swift "$ICONSET"
iconutil -c icns "$ICONSET" -o "Resources/AppIcon.icns"
rm -rf "$ICONSET"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$BIN_DIR/$EXECUTABLE" "$APP/Contents/MacOS/$EXECUTABLE"

# SwiftPM emits resource bundles (MarkdownUI, cmark, …) next to the binary.
# Bundle.module locates them adjacent to the executable, so copy them into
# Contents/MacOS. Missing this = blank render at runtime.
shopt -s nullglob
for bundle in "$BIN_DIR"/*.bundle; do
    echo "    + $(basename "$bundle")"
    cp -R "$bundle" "$APP/Contents/MacOS/"
done
shopt -u nullglob

cp "Resources/Info.plist" "$APP/Contents/Info.plist"
cp "Resources/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"

echo "==> Ad-hoc code-signing (no Apple Developer account needed)"
codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP"
codesign --verify --verbose "$APP" || true

echo ""
echo "✅ Built: $APP"
echo "   Run it:      open \"$APP\""
echo "   Install it:  ./scripts/install.sh"
