#!/bin/bash

# Arguments
# $1 = Path to the downloaded Zip file (e.g., /tmp/ImmoScoutNew.zip)
# $2 = Path to the current App (e.g., /Applications/ImmoScoutAutomation.app)
# $3 = PID of the old App (to wait for it to close)

ZIP_PATH="$1"
APP_PATH="$2"
OLD_PID="$3"
APP_DIR=$(dirname "$APP_PATH")
APP_NAME=$(basename "$APP_PATH")

echo "🚀 Updater started for $APP_NAME"
echo "waiting for PID $OLD_PID to quit..."

# Wait for the main app to close
while kill -0 "$OLD_PID" 2>/dev/null; do
    sleep 0.5
done

echo "✅ App closed. Starting update..."

# Unzip to a temporary location
TEMP_EXTRACT_DIR=$(mktemp -d)
unzip -o -q "$ZIP_PATH" -d "$TEMP_EXTRACT_DIR"

# Find the .app in the extracted files
NEW_APP_PATH=$(find "$TEMP_EXTRACT_DIR" -maxdepth 2 -name "*.app" | head -n 1)

if [ -z "$NEW_APP_PATH" ]; then
    echo "❌ No .app found in update zip."
    exit 1
fi

echo "📦 Found new version: $NEW_APP_PATH"

# Replace the old app
rm -rf "$APP_PATH"
mv "$NEW_APP_PATH" "$APP_DIR/"

# Cleanup
rm -rf "$TEMP_EXTRACT_DIR"
rm "$ZIP_PATH"

echo "🎉 Update finished. Relaunching..."

# Relaunch the new app
open "$APP_PATH"

exit 0
