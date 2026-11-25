#!/bin/bash
#
# Checks a built ClockSpace.app before it ships: universal binary, bundled
# catalog present, and nothing private or left over inside it.
#
# Usage: scripts/check_bundle.sh path/to/ClockSpace.app
# Set EXPECTED_VERSION (e.g. 1.1.0) to also require that version.

set -euo pipefail

APP="${1:?usage: check_bundle.sh path/to/ClockSpace.app}"
BIN="$APP/Contents/MacOS/ClockSpace"
fail() { echo "❌ check_bundle: $*" >&2; exit 1; }

[ -x "$BIN" ] || fail "no executable at $BIN"

ARCHS=$(lipo -archs "$BIN")
for arch in arm64 x86_64; do
    [[ " $ARCHS " == *" $arch "* ]] || fail "missing $arch code (has: $ARCHS)"
done

[ -f "$APP/Contents/Resources/catalog.json" ] || fail "bundled catalog.json missing"
[ ! -e "$APP/Contents/Frameworks" ] || fail "unexpected Frameworks folder: $(ls "$APP/Contents/Frameworks")"

# Build config, old Firebase files, entitlements, source and Finder litter must not ship.
LEFTOVERS=$(find "$APP" \( -name '*.xcconfig' -o -name 'GoogleService-Info.plist' \
    -o -name '*.entitlements' -o -name '*.swift' -o -name '.DS_Store' \) -print)
[ -z "$LEFTOVERS" ] || fail "files that must not ship:"$'\n'"$LEFTOVERS"

# A home-folder path in the binary would reveal who built it.
if strings -a "$BIN" | grep -q '/Users/'; then
    fail "the binary contains a /Users/ path"
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")
if [ -n "${EXPECTED_VERSION:-}" ] && [ "$VERSION" != "$EXPECTED_VERSION" ]; then
    fail "version is $VERSION, expected $EXPECTED_VERSION"
fi

echo "✅ check_bundle: $(basename "$APP") $VERSION ($ARCHS) is clean"
