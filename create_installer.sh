#!/bin/zsh

# Mira Beautiful DMG Installer Creator
# Copyright (c) 2026 Miguel Angel Benajes

set -e

APP_NAME="Mira"
DMG_NAME="Mira_Installer.dmg"
VOL_NAME="Install Mira"
SOURCE_DIR="dmg_content"
MIRA_FOLDER="Mira"

echo "Running bundle script..."
./bundle_app.sh

# ... (previous code for app bundling) ...

echo "Removing old DMG files..."
rm -f "$DMG_NAME"
rm -f "pack.temp.dmg"

echo "Creating beautiful DMG structure..."
rm -rf "$SOURCE_DIR"
mkdir -p "$SOURCE_DIR"

# Packaging Mira app...
echo "Packaging Mira app..."
cp -R "$APP_NAME.app" "$SOURCE_DIR/"
# Remove quarantine so users don't get Gatekeeper blocks
xattr -cr "$SOURCE_DIR/$APP_NAME.app" 2>/dev/null || true
ln -s /Applications "$SOURCE_DIR/Applications"

# Step 1: Create a temporary disk image
echo "Creating temporary DMG..."
hdiutil create -srcfolder "$SOURCE_DIR" -volname "$VOL_NAME" -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" -format UDRW -size 100m pack.temp.dmg

# Step 2: Mount it and apply background/styling
echo "Mounting temporary DMG..."
# Ensure we detach any existing mount first
hdiutil detach "/Volumes/$VOL_NAME" 2>/dev/null || true
device=$(hdiutil attach -readwrite -noverify pack.temp.dmg | egrep '^/dev/' | sed 1q | awk '{print $1}')
sleep 3

# Copy background
echo "Applying styling..."
mkdir -p "/Volumes/$VOL_NAME/.background"
cp "Assets/dmg_background_corporate.png" "/Volumes/$VOL_NAME/.background/background.png"

# Use AppleScript to set visual style
echo "Running AppleScript for DMG styling..."
osascript <<EOF
tell application "Finder"
    tell disk "$VOL_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 100, 1040, 740} -- 640x640 starting at 400,100
        set viewOptions to the icon view options of container window
        set icon size of viewOptions to 80
        set arrangement of viewOptions to not arranged
        set background picture of viewOptions to file ".background:background.png"
        
        -- Position icons (X, Y)
        set position of item "$APP_NAME.app" of container window to {160, 340}
        set position of item "Applications" of container window to {480, 340}
        
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

# Give Finder a moment
sleep 2

echo "Detaching and finalizing..."
hdiutil detach "$device"
rm -rf "$SOURCE_DIR"

# Step 3: Convert to final compressed DMG
echo "Converting to final compressed DMG..."
hdiutil convert "pack.temp.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG_NAME"
rm -f "pack.temp.dmg"

echo ""
echo "✅ Done! Beautifully customized installer created at $DMG_NAME"
echo ""
echo "📦 DMG Contents:"
echo "   ├── Mira.app (positioned for drag-and-drop)"
echo "   └── Applications (positioned for drag-and-drop)"
