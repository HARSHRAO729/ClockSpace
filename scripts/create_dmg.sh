#!/bin/bash

# ClockSpace Professional DMG Creator
# Creates a premium, brand-aligned installer with background and custom layout.

set -e

# --- Configuration ---
PROJECT_NAME="ClockSpace"
APP_NAME="ClockSpace"
VOL_NAME="ClockSpace"
BUILD_DIR="./build"
EXPORT_PATH="$BUILD_DIR/Export"
APP_BUNDLE="$EXPORT_PATH/$APP_NAME.app"
DMG_BACKGROUND_IMG="ClockSpaceApp/Resources/dmg_background_final.png"
VOLUME_ICON="ClockSpaceApp/Resources/AppIcon.icns"
FINAL_DMG="ClockSpace.dmg"
TEMP_DMG="$BUILD_DIR/temp.dmg"
STAGING_DIR="$BUILD_DIR/dmg_staging"

echo "🎨 Creating premium DMG for $APP_NAME..."

# 1. Cleanup & Preparation
hdiutil detach "/Volumes/$VOL_NAME" -force 2>/dev/null || true
rm -f "$FINAL_DMG"
rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Ensure the app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at $APP_BUNDLE. Run build_release.sh first."
    exit 1
fi

# 2. Ad-hoc Code Signing (Required for M1/M2/M3)
echo "🔐 Applying ad-hoc code signature..."
codesign --force --deep --sign - --options runtime --entitlements ClockSpaceApp/ClockSpace.entitlements "$APP_BUNDLE"

# 3. Staging
echo "📁 Staging files..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Add background (hidden folder)
mkdir -p "$STAGING_DIR/.background"
cp "$DMG_BACKGROUND_IMG" "$STAGING_DIR/.background/background.png"

# Add volume icon if it exists
if [ -f "$VOLUME_ICON" ]; then
    cp "$VOLUME_ICON" "$STAGING_DIR/.VolumeIcon.icns"
fi

# 4. Create the temporary R/W Disk Image
echo "📀 Creating temporary disk image..."
hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOL_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 400m "$TEMP_DMG"

# 5. Mount and Configure Layout via AppleScript
echo "🔧 Configuring DMG layout..."
device=$(hdiutil attach -readwrite -noverify "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 3

# Use AppleScript to set the visual properties
echo "🖥️ Applying visual styles..."
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1000, 500}
        set theViewOptions to the icon view options of container window
        set icon size of theViewOptions to 120
        set arrangement of theViewOptions to not arranged
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "$APP_NAME.app" of container window to {160, 200}
        set position of item "Applications" of container window to {440, 200}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Set volume icon attribute
if [ -f "$STAGING_DIR/.VolumeIcon.icns" ]; then
    # Use SetFile to show volume icon if developer tools are available
    if command -v SetFile >/dev/null 2>&1; then
        SetFile -a C "/Volumes/$VOL_NAME"
    fi
fi

# 6. Finalize
echo "🔒 Finalizing DMG..."
sync
hdiutil detach "$device"

# Convert to compressed, read-only DMG
echo "📦 Converting to compressed DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

# Cleanup
rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"

echo "--------------------------------------------------"
echo "🎉 Success! Created $FINAL_DMG"
echo "--------------------------------------------------"
