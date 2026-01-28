#!/bin/bash

# Configuration
APP_NAME="ImmoScoutAutomation"
SOURCE_FILE="src/main.applescript"
BUILD_DIR="build"

# Ensure build directory exists
mkdir -p "$BUILD_DIR"

# Compile AppleScript to Application Bundle
echo "🔨 Compiling $APP_NAME.app..."
osacompile -o "$BUILD_DIR/$APP_NAME.app" "$SOURCE_FILE"

if [ $? -eq 0 ]; then
    echo "✅ Build successful: $BUILD_DIR/$APP_NAME.app"
else
    echo "❌ Build failed!"
    exit 1
fi
