#!/usr/bin/env bash
# Install the built app into ~/Applications and register it with Launch
# Services so it shows up in Finder's right-click → "Open With".
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="Markdown Viewer"
APP="dist/$APP_NAME.app"
DEST_DIR="$HOME/Applications"

if [ ! -d "$APP" ]; then
    echo "❌ $APP not found. Build it first:  ./scripts/build.sh"
    exit 1
fi

mkdir -p "$DEST_DIR"
echo "==> Installing to $DEST_DIR/$APP_NAME.app"
rm -rf "$DEST_DIR/$APP_NAME.app"
cp -R "$APP" "$DEST_DIR/"

# Locally built apps aren't quarantined, but clear it defensively so Gatekeeper
# never nags on this machine.
xattr -dr com.apple.quarantine "$DEST_DIR/$APP_NAME.app" 2>/dev/null || true

LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"
echo "==> Registering with Launch Services"
"$LSREGISTER" -f "$DEST_DIR/$APP_NAME.app"

echo ""
echo "✅ Installed. Now, in Finder:"
echo "   • Right-click any .md file → Open With → \"$APP_NAME\""
echo "   • To make it the default: Get Info → Open with → $APP_NAME → Change All…"
