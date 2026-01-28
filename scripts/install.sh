#!/bin/bash
set -e

REPO="EndlessHoper/portwatch"
APP_NAME="PortWatch"
INSTALL_DIR="$HOME/Applications"

echo "Installing $APP_NAME..."

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" != "arm64" ]; then
    echo "Error: Only Apple Silicon (arm64) is supported"
    exit 1
fi

# Get latest release URL
DOWNLOAD_URL=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep "browser_download_url.*arm64.zip" | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    echo "Error: Could not find latest release"
    exit 1
fi

# Download and extract
TEMP_DIR=$(mktemp -d)
curl -L "$DOWNLOAD_URL" -o "$TEMP_DIR/$APP_NAME.zip"
unzip -q "$TEMP_DIR/$APP_NAME.zip" -d "$TEMP_DIR"

# Install
mkdir -p "$INSTALL_DIR"
rm -rf "$INSTALL_DIR/$APP_NAME.app"
mv "$TEMP_DIR/$APP_NAME.app" "$INSTALL_DIR/"

# Remove quarantine (unsigned app)
xattr -cr "$INSTALL_DIR/$APP_NAME.app" 2>/dev/null || true

# Cleanup
rm -rf "$TEMP_DIR"

echo "✓ Installed to $INSTALL_DIR/$APP_NAME.app"
echo ""

# Launch the app
open "$INSTALL_DIR/$APP_NAME.app"

echo "✓ PortWatch is now running in your menu bar (look for ⚓)"
echo ""
echo "To uninstall: rm -rf '$INSTALL_DIR/$APP_NAME.app'"
