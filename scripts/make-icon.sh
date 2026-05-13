#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/Resources/AppIcon.png"
ICONSET="$ROOT/Resources/AppIcon.iconset"
OUT="$ROOT/Resources/AppIcon.icns"

if [ ! -f "$SRC" ]; then
  echo "Source not found: $SRC" >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

while IFS=' ' read -r size name; do
  sips -z "$size" "$size" "$SRC" --out "$ICONSET/icon_${name}.png" >/dev/null
done <<EOF
16 16x16
32 16x16@2x
32 32x32
64 32x32@2x
128 128x128
256 128x128@2x
256 256x256
512 256x256@2x
512 512x512
1024 512x512@2x
EOF

iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$ICONSET"
echo "Built: $OUT"
