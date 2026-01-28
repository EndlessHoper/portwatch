#!/bin/bash
set -e

VERSION="${1:-0.1.0}"
APP_NAME="PortWatch"
BUILD_DIR=".build/release"
DIST_DIR="dist"

echo "Building $APP_NAME v$VERSION..."

# Build release binary
swift build -c release

# Create app bundle
mkdir -p "$DIST_DIR/$APP_NAME.app/Contents/MacOS"
mkdir -p "$DIST_DIR/$APP_NAME.app/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$DIST_DIR/$APP_NAME.app/Contents/MacOS/"

cat > "$DIST_DIR/$APP_NAME.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourname.portwatch</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Create zip for distribution
cd "$DIST_DIR"
zip -r "$APP_NAME-$VERSION-arm64.zip" "$APP_NAME.app"
echo "Created $DIST_DIR/$APP_NAME-$VERSION-arm64.zip"
