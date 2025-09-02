#!/bin/bash

# KeyBoy DMG Creation Script
set -e

APP_NAME="KeyBoy"
VERSION="1.0.0"  # Update this for releases
BUNDLE_PATH="./build/Build/Products/Release/${APP_NAME}.app"
DMG_NAME="${APP_NAME}"
TEMP_DMG="${DMG_NAME}-temp.dmg"
FINAL_DMG="${DMG_NAME}.dmg"
VOLUME_NAME="${APP_NAME}"

echo "🚀 Creating DMG for ${APP_NAME} v${VERSION}..."

# Clean up any existing files
rm -f "${TEMP_DMG}" "${FINAL_DMG}"
rm -rf "./dmg-staging"

# Build the app in Release mode
echo "📦 Building ${APP_NAME} in Release mode..."
xcodebuild -scheme "${APP_NAME}" -configuration Release -derivedDataPath ./build clean build

# Verify the app was built
if [ ! -d "${BUNDLE_PATH}" ]; then
    echo "❌ Error: ${BUNDLE_PATH} not found. Build may have failed."
    exit 1
fi

# Create staging directory
mkdir -p "./dmg-staging"
cp -R "${BUNDLE_PATH}" "./dmg-staging/"

# Create symbolic link to Applications
ln -s /Applications "./dmg-staging/Applications"

# Calculate size needed for DMG (app size + 50MB buffer)
APP_SIZE=$(du -sm "./dmg-staging" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))

echo "📏 App size: ${APP_SIZE}MB, DMG size: ${DMG_SIZE}MB"

# Create temporary DMG
echo "💿 Creating temporary DMG..."
hdiutil create -srcfolder "./dmg-staging" -volname "${VOLUME_NAME}" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size "${DMG_SIZE}m" "${TEMP_DMG}"

# Mount the DMG
echo "🔧 Mounting DMG for customization..."
DEVICE=$(hdiutil attach -readwrite -noverify "${TEMP_DMG}" | egrep '^/dev/' | sed 1q | awk '{print $1}')
MOUNT_PATH="/Volumes/${VOLUME_NAME}"

# Wait for mount
sleep 2

# Set DMG window properties and icon positions
echo "🎨 Customizing DMG appearance..."
cat > "./dmg-staging/dmg-setup.applescript" << 'EOF'
tell application "Finder"
    tell disk "KeyBoy"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 900, 400}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 72
        set position of item "KeyBoy.app" of container window to {150, 150}
        set position of item "Applications" of container window to {350, 150}
        close
        open
        update without registering applications
        delay 2
    end tell
end tell
EOF

# Run AppleScript to customize DMG
osascript "./dmg-staging/dmg-setup.applescript" || echo "⚠️  DMG customization may have failed, continuing..."

# Clean up
rm -f "./dmg-staging/dmg-setup.applescript"

# Unmount the DMG
echo "⏏️  Unmounting DMG..."
hdiutil detach "${DEVICE}"

# Convert to final compressed DMG
echo "🗜️  Creating final compressed DMG..."
hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${FINAL_DMG}"

# Clean up
rm -f "${TEMP_DMG}"
rm -rf "./dmg-staging"
rm -rf "./build"

echo "✅ DMG created successfully: ${FINAL_DMG}"
echo "📁 File size: $(du -h "${FINAL_DMG}" | cut -f1)"

# Verify DMG
echo "🔍 Verifying DMG..."
hdiutil verify "${FINAL_DMG}"

echo "🎉 DMG creation complete! Ready for distribution."