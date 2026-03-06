#!/bin/zsh

APP_NAME="Mira"
OUTPUT_DIR="."
EXECUTABLE_NAME="Mira"

echo "Building $APP_NAME..."
swift build -c release

if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

echo "Creating Bundle Structure..."
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources"

echo "Copying Executable..."
cp ".build/release/$EXECUTABLE_NAME" "$OUTPUT_DIR/$APP_NAME.app/Contents/MacOS/$APP_NAME"

echo "Creating Info.plist..."
cat > "$OUTPUT_DIR/$APP_NAME.app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.coyote.Mira</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/> 
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 Miguel Angel Benajes. All rights reserved.</string>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Mira needs screen recording access to display your monitors in floating windows.</string>
</dict>
</plist>
EOF

# Note: LSUIElement true makes it an agent app (no dock icon), which fits the "Menu Bar" app style.
# If user wants Dock icon, we can remove LSUIElement or set to false.
# Given "Menu Bar" focus, LSUIElement is usually desired, but user said "double click and run".
# Agent apps can still be double clicked.

# Setting up Icon
# Use the local eye logo
ICON_SOURCE="Assets/eye_logo.png"

if [ -f "$ICON_SOURCE" ]; then
    echo "Creating iconset..."
    mkdir Mira.iconset
    
    # Convert source to a proper PNG first (in case it's a JPEG or other format)
    sips -s format png "$ICON_SOURCE" --out Mira.iconset/source.png
    
    ICON_PNG="Mira.iconset/source.png"
    
    # Resize to standard sizes
    sips -z 16 16     "$ICON_PNG" --out Mira.iconset/icon_16x16.png
    sips -z 32 32     "$ICON_PNG" --out Mira.iconset/icon_16x16@2x.png
    sips -z 32 32     "$ICON_PNG" --out Mira.iconset/icon_32x32.png
    sips -z 64 64     "$ICON_PNG" --out Mira.iconset/icon_32x32@2x.png
    sips -z 128 128   "$ICON_PNG" --out Mira.iconset/icon_128x128.png
    sips -z 256 256   "$ICON_PNG" --out Mira.iconset/icon_128x128@2x.png
    sips -z 256 256   "$ICON_PNG" --out Mira.iconset/icon_256x256.png
    sips -z 512 512   "$ICON_PNG" --out Mira.iconset/icon_256x256@2x.png
    sips -z 512 512   "$ICON_PNG" --out Mira.iconset/icon_512x512.png
    sips -z 1024 1024 "$ICON_PNG" --out Mira.iconset/icon_512x512@2x.png
    
    # Remove intermediate source
    rm "$ICON_PNG"
    
    echo "Converting to icns..."
    iconutil -c icns Mira.iconset
    
    cp Mira.icns "$OUTPUT_DIR/$APP_NAME.app/Contents/Resources/AppIcon.icns"
    
    rm -rf Mira.iconset
    rm Mira.icns
else
    echo "Icon source not found at $ICON_SOURCE"
fi

# Ad-hoc code sign the app so Gatekeeper doesn't block it on other Macs
echo "Ad-hoc signing the application..."
codesign --force --deep --sign - \
    --entitlements "Mira.entitlements" \
    "$OUTPUT_DIR/$APP_NAME.app"

# Remove quarantine attribute (in case it gets set during build)
xattr -cr "$OUTPUT_DIR/$APP_NAME.app" 2>/dev/null || true

echo "Verifying signature..."
codesign --verify --verbose "$OUTPUT_DIR/$APP_NAME.app" && echo "Signature OK" || echo "Warning: signature verification failed"

echo "Done! Application bundle created at $OUTPUT_DIR/$APP_NAME.app"
