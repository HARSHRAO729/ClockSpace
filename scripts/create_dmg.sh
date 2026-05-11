#!/bin/bash

# ClockSpace Premium DMG Creator
# This script automates the creation of a beautiful, brand-aligned DMG installer.

set -e

PROJECT_NAME="ClockSpace"
APP_NAME="ClockSpace"
BUILD_DIR="./build"
EXPORT_PATH="$BUILD_DIR/Export"
APP_BUNDLE="$EXPORT_PATH/$APP_NAME.app"
DMG_BACKGROUND="ClockSpaceApp/Resources/dmg_background_final.jpg"
FINAL_DMG="ClockSpace.dmg"
VOL_NAME="ClockSpace"

echo "🎨 Creating premium DMG for $APP_NAME..."

# 1. Cleanup & Preparation
rm -f "$FINAL_DMG"
TEMP_DMG="$BUILD_DIR/temp.dmg"
STAGING_DIR="$BUILD_DIR/dmg_staging"
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

# Ensure the app exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ Error: App bundle not found at $APP_BUNDLE. Run build_release.sh first."
    exit 1
fi

# 2. Copy App and create Applications symlink
echo "📁 Staging files..."
cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# 3. Create a temporary R/W Disk Image
echo "📀 Creating temporary disk image..."
rm -f "$TEMP_DMG"
hdiutil create -srcfolder "$STAGING_DIR" -volname "$VOL_NAME" -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" -format UDRW -size 800m "$TEMP_DMG"

# 4. Mount the image
echo "🔌 Mounting image..."
MOUNT_DIR="/Volumes/$VOL_NAME"
# Unmount if already mounted
if [ -d "$MOUNT_DIR" ]; then hdiutil detach "$MOUNT_DIR" -force; fi

# Attach and get the device name
DEVICE=$(hdiutil attach -readwrite -noverify "$TEMP_DMG" | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 2 # Wait for mount to stabilize

# 5. Apply Customizations
echo "✨ Applying visual customizations..."

# Set background image (hidden folder)
mkdir "$MOUNT_DIR/.background"
cp "$DMG_BACKGROUND" "$MOUNT_DIR/.background/background.jpg"

# Use AppleScript to configure the Finder window
# Note: Bounds are {left, top, right, bottom}
# Window size will be 600x400
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        
        -- Set window size and position
        set the bounds of container window to {100, 100, 700, 500}
        
        set viewOptions to the icon view options of container window
        set icon size of viewOptions to 100
        set arrangement of viewOptions to not arranged
        set background picture of viewOptions to file ".background:background.jpg"
        
        -- Position the icons precisely over silhouettes
        set position of item "$APP_NAME.app" to {150, 240}
        set position of item "Applications" to {450, 240}
        
        update (every item)
        close
    end tell
end tell
EOF

# Give Finder a moment to save its state (.DS_Store)
sleep 2

# 6. Finalize
echo "📦 Finalizing DMG..."
chmod -Rf go-w "$MOUNT_DIR" || true
hdiutil detach "$DEVICE"
sleep 2

# Convert to compressed, read-only DMG
hdiutil convert "$TEMP_DMG" -format UDZO -imagekey zlib-level=9 -o "$FINAL_DMG"

# Cleanup
rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"

echo "--------------------------------------------------"
echo "🎉 Success! Created $FINAL_DMG"
echo "--------------------------------------------------"
