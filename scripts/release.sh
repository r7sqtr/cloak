#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <version>   e.g. $0 v1.0.0" >&2
  exit 1
fi

VERSION="$1"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "Working tree is not clean. Commit or stash changes first." >&2
  git status --short
  exit 1
fi

if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "Tag $VERSION already exists." >&2
  exit 1
fi

bash "$ROOT/scripts/build-app.sh"

APP_DIR="$ROOT/build/Cloak.app"
if [ ! -d "$APP_DIR" ]; then
  echo "Cloak.app not found at $APP_DIR" >&2
  exit 1
fi

ZIP="$ROOT/build/Cloak-$VERSION.zip"
rm -f "$ZIP"
(cd "$ROOT/build" && /usr/bin/ditto -c -k --keepParent Cloak.app "Cloak-$VERSION.zip")

git tag -a "$VERSION" -m "Release $VERSION"
git push origin "$VERSION"

NOTES_FILE="$(mktemp)"
cat >"$NOTES_FILE" <<EOF
## Install

1. Download \`Cloak-$VERSION.zip\` below and unzip.
2. Move \`Cloak.app\` to your \`/Applications\` folder.
3. On first launch macOS will block the app (Gatekeeper) because it is ad-hoc signed:
   - Right-click \`Cloak.app\` → **Open** → confirm in the dialog, **OR**
   - Run: \`xattr -dr com.apple.quarantine /Applications/Cloak.app\`
4. The clock will appear on every connected display. A menu bar icon provides Settings and Quit.

Built from commit \`$(git rev-parse --short HEAD)\`.
EOF

gh release create "$VERSION" "$ZIP" \
  --title "$VERSION" \
  --notes-file "$NOTES_FILE"

rm -f "$NOTES_FILE"
echo "Released: $VERSION"
echo "Asset: $ZIP"
