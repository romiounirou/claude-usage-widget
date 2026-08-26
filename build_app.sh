#!/bin/bash
# Builds ClaudeUsageWidget and packages it as a double-clickable .app bundle
# in this project's root folder.
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
swift build -c "$CONFIG"

APP_NAME="Claude Usage.app"
BIN_PATH=".build/$CONFIG/ClaudeUsageWidget"
APP_DIR="$APP_NAME/Contents"

rm -rf "$APP_NAME"
mkdir -p "$APP_DIR/MacOS"
cp "$BIN_PATH" "$APP_DIR/MacOS/ClaudeUsageWidget"
cp Resources/Info.plist "$APP_DIR/Info.plist"

echo "Built $APP_NAME"
