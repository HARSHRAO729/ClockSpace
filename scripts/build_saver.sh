#!/bin/bash
# Build a native Swift screensaver into a universal (arm64 + x86_64), signed .saver bundle.
#
# Usage:
#   scripts/build_saver.sh <source.swift> <ModuleName> <PrincipalClass> <DisplayName> <bundle-id> [out-dir]
#
# Example:
#   scripts/build_saver.sh native-savers/WordClock/WordClockSaver.swift \
#       WordClock WordClockView "Word Clock" space.clock.wordclock dist/savers
#
# Signs with SAVER_SIGN_ID if set, else the first Apple Development identity, else adhoc.
set -euo pipefail

SRC="$1"; MODULE="$2"; PRINCIPAL="$3"; DISPLAY="$4"; BUNDLE_ID="$5"; OUT="${6:-dist/savers}"
DEPLOY="${SAVER_DEPLOY_TARGET:-13.0}"
BUNDLE="$OUT/$MODULE.saver"
MACOS="$BUNDLE/Contents/MacOS"
work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT

echo "▶ Building $DISPLAY ($MODULE) universal…"
rm -rf "$BUNDLE"
mkdir -p "$MACOS" "$BUNDLE/Contents/Resources"

for arch in arm64 x86_64; do
  xcrun --sdk macosx swiftc "$SRC" \
    -module-name "$MODULE" \
    -target "${arch}-apple-macos${DEPLOY}" \
    -framework ScreenSaver -framework SwiftUI -framework AppKit \
    -Xlinker -bundle -O -o "$work/bin_${arch}"
done
lipo -create "$work/bin_arm64" "$work/bin_x86_64" -output "$MACOS/$MODULE"

# Gallery thumbnail: macOS reads Contents/Resources/thumbnail.png (+@2x, 90x58 / 180x116).
# Copy them from the source dir if present.
SRC_DIR="$(dirname "$SRC")"
for t in thumbnail.png thumbnail@2x.png; do
  [ -f "$SRC_DIR/$t" ] && cp "$SRC_DIR/$t" "$BUNDLE/Contents/Resources/$t" && echo "▶ bundled $t"
done

# Info.plist — NSPrincipalClass must be <Module>.<Class>
cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleDevelopmentRegion</key><string>en</string>
  <key>CFBundleExecutable</key><string>$MODULE</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleName</key><string>$DISPLAY</string>
  <key>CFBundlePackageType</key><string>BNDL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>$DEPLOY</string>
  <key>NSPrincipalClass</key><string>${MODULE}.${PRINCIPAL}</string>
  <key>NSHumanReadableCopyright</key><string>ClockSpace — open source</string>
</dict></plist>
PLIST

# Sign: explicit id > Apple Development > adhoc
SIGN_ID="${SAVER_SIGN_ID:-}"
if [ -z "$SIGN_ID" ]; then
  SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
    | grep -m1 'Apple Development' | awk -F'"' '{print $2}')"
fi
if [ -n "$SIGN_ID" ]; then
  echo "▶ Signing with: $SIGN_ID"
  codesign --force --deep --timestamp=none -s "$SIGN_ID" "$BUNDLE"
else
  echo "▶ No identity found — adhoc signing"
  codesign --force --deep -s - "$BUNDLE"
fi

echo "✅ $BUNDLE"
echo "   archs : $(lipo -archs "$MACOS/$MODULE")"
codesign -dvv "$BUNDLE" 2>&1 | grep -E 'Authority|Signature|adhoc' | head -3 || true
