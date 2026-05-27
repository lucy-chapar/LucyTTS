#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SDK_PATH="${SDKROOT:-/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk}"
OUTPUT_DIR="$ROOT_DIR/.build/direct"
APP_DIR="$OUTPUT_DIR/LiveFishTTS.app"
OUTPUT="$APP_DIR/Contents/MacOS/LiveFishTTS"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Resources/LucyTTS.icns" "$APP_DIR/Contents/Resources/LucyTTS.icns"
printf "APPL????" > "$APP_DIR/Contents/PkgInfo"

swiftc \
  -sdk "$SDK_PATH" \
  -target arm64-apple-macos13.0 \
  "$ROOT_DIR"/Sources/LiveFishTTS/**/*.swift \
  -o "$OUTPUT"

echo "$APP_DIR"
