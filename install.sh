#!/bin/bash

APP_NAME="ImmoScoutAutomation"
CONFIG_DIR="$HOME/Library/Application Support/ImmoScout-Automation"
CONFIG_FILE="$CONFIG_DIR/config.txt"
INSTALL_DIR="/Applications"

echo "🚀 Starting Installation for $APP_NAME..."

# 1. Check Config (Read-Only)
if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚠️  NOTE: No config found at $CONFIG_FILE"
    echo "👉 You must create this file manually using the template in 'config/config.template.txt'."
else
    echo "✅ Config file found."
fi

# 3. Build & Install App
echo "🔨 Building App..."
./scripts/build.sh

if [ -d "build/$APP_NAME.app" ]; then
    echo "📦 Installing to $INSTALL_DIR..."
    # Remove old version if exists
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
    # Move new version
    mv "build/$APP_NAME.app" "$INSTALL_DIR/"
    
    echo "🎉 Success! App installed to Applications folder."
    echo "👉 You can now launch '$APP_NAME' from Spotlight or Finder."
else
    echo "❌ Build failed. Installation aborted."
    exit 1
fi
