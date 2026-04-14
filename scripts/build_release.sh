#!/bin/bash

# ClockSpace Build & Package Script
# This script automates the creation of a .dmg installer for ClockSpace.

set -e

PROJECT_NAME="ClockSpace"
SCHEME_NAME="ClockSpace"
BUILD_DIR="./build"
ARCHIVE_PATH="$BUILD_DIR/$PROJECT_NAME.xcarchive"
EXPORT_PATH="$BUILD_DIR/Export"
DMG_NAME="ClockSpace.dmg"

echo "🚀 Starting build process for $PROJECT_NAME..."

# 1. Clean up old builds
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# 2. Archive the project
echo "📦 Archiving project..."
xcodebuild archive \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -quiet

# 3. Export the app
# Note: For simple local distribution without a developer cert, 
# we can just copy the .app from the archive.
echo "📤 Exporting .app bundle..."
APP_BUNDLE_PATH=$(find "$ARCHIVE_PATH" -name "*.app" -type d | head -n 1)

if [ -z "$APP_BUNDLE_PATH" ]; then
    echo "❌ Error: Could not find .app in archive."
    exit 1
fi

mkdir -p "$EXPORT_PATH"
cp -R "$APP_BUNDLE_PATH" "$EXPORT_PATH/"
EXPORTED_APP="$EXPORT_PATH/$(basename "$APP_BUNDLE_PATH")"

echo "✅ App exported to: $EXPORTED_APP"

# 4. Create DMG
echo "💿 Creating DMG..."
if [ -f "$DMG_NAME" ]; then rm "$DMG_NAME"; fi

hdiutil create -volname "$PROJECT_NAME" -srcfolder "$EXPORT_PATH" -ov -format UDZO "$DMG_NAME"

echo "--------------------------------------------------"
echo "🎉 Success! Created $DMG_NAME"
echo "You can now upload this file to your GitHub Release."
echo "--------------------------------------------------"
