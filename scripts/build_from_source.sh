#!/bin/bash
# Modernize + build an ORIGINAL open-source screensaver for current macOS.
# Clones the upstream repo (if needed), forces a universal build (arm64 + x86_64)
# with a modern deployment target, signs it, and drops the .saver in the out dir.
#
# Usage: scripts/build_from_source.sh <github-owner/repo> [out-dir]
# The upstream repo is the source of truth; we only override build settings.
set -euo pipefail

SLUG="$1"; OUT="${2:-dist/savers-original}"
DEPLOY="${SAVER_DEPLOY_TARGET:-13.0}"
CACHE="${SAVER_SRC_CACHE:-/tmp/saver-src}"
name="$(basename "$SLUG")"
repo="$CACHE/$name"
mkdir -p "$CACHE" "$OUT"

[ -d "$repo/.git" ] || git clone --depth 1 "https://github.com/$SLUG.git" "$repo" >/dev/null 2>&1 \
  || { echo "❌ $name: clone failed"; exit 1; }

proj="$(find "$repo" -name '*.xcodeproj' -maxdepth 3 | head -1)"
[ -n "$proj" ] || { echo "❌ $name: no .xcodeproj"; exit 1; }

# Pick the screensaver target: first that isn't Preview/Tests.
target="$(xcodebuild -list -project "$proj" 2>/dev/null \
  | awk '/Targets:/{f=1;next} /Build Configurations:|Schemes:/{f=0} f{gsub(/^ +/,"");print}' \
  | grep -viE '^(Preview|.*[Tt]ests?)$' | head -1)"
[ -n "$target" ] || { echo "❌ $name: no target"; exit 1; }

log="/tmp/bfs_${name}.log"
if ! xcodebuild -project "$proj" -target "$target" -configuration Release \
      ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO MACOSX_DEPLOYMENT_TARGET="$DEPLOY" \
      CODE_SIGNING_ALLOWED=NO clean build >"$log" 2>&1; then
  echo "❌ $name: BUILD FAILED — $(grep -m1 -iE 'error:' "$log" | sed 's/^ *//' | cut -c1-90)"
  exit 2
fi

# Product may land in ./build or a nested subproject build dir — search the whole repo.
saver="$(find "$repo" -name '*.saver' -path '*/Release/*' | head -1)"
[ -n "$saver" ] || saver="$(find "$repo" -name '*.saver' -path '*build*' | head -1)"
[ -n "$saver" ] || { echo "❌ $name: no .saver produced"; exit 3; }
dst="$OUT/$(basename "$saver")"
rm -rf "$dst"; cp -R "$saver" "$dst"
# preserve upstream license alongside the build for attribution
lic="$(find "$repo" -maxdepth 2 -iname 'license*' | head -1)"
[ -n "$lic" ] && cp "$lic" "$OUT/$(basename "$saver" .saver).LICENSE" 2>/dev/null || true

ID="$(security find-identity -v -p codesigning | grep -m1 'Apple Development' | awk -F'"' '{print $2}')"
[ -n "$ID" ] && codesign --force --deep --timestamp=none -s "$ID" "$dst" >/dev/null 2>&1 || codesign --force --deep -s - "$dst" >/dev/null 2>&1
echo "✅ $name → $(basename "$saver")  archs=$(lipo -archs "$dst/Contents/MacOS/"* 2>/dev/null | head -1)"
