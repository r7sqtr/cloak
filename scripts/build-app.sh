#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

CONFIG="${CONFIG:-release}"

swift build -c "$CONFIG"

BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"
APP_DIR="$ROOT/build/Cloak.app"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH/Cloak" "$APP_DIR/Contents/MacOS/Cloak"
cp "$ROOT/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"

if [ ! -f "$ROOT/Resources/AppIcon.icns" ] && [ -f "$ROOT/Resources/AppIcon.png" ]; then
  "$ROOT/scripts/make-icon.sh"
fi
if [ -f "$ROOT/Resources/AppIcon.icns" ]; then
  cp "$ROOT/Resources/AppIcon.icns" "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "Built: $APP_DIR"
