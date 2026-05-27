#!/usr/bin/env bash
# Build LiveFishTTS into a .app bundle without using SwiftPM. Useful when
# `swift run` from a terminal breaks native AppKit text input focus.
# Output: path to the freshly built .app bundle, printed on stdout.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=scripts/_select_xcode.sh
source "$SCRIPT_DIR/_select_xcode.sh"
select_xcode

# Resolve a usable macOS SDK from the selected Xcode. Falls back to whatever
# `xcrun` thinks is current if the standard path layout ever changes.
SDK_PATH="${SDKROOT:-}"
if [[ -z "$SDK_PATH" ]]; then
    # /usr/bin/xcrun is a shim that honors the exported DEVELOPER_DIR; Xcode
    # itself does not ship an xcrun binary at $DEVELOPER_DIR/usr/bin/xcrun.
    SDK_PATH="$(/usr/bin/xcrun --sdk macosx --show-sdk-path 2>/dev/null || true)"
fi
if [[ -z "$SDK_PATH" || ! -d "$SDK_PATH" ]]; then
    echo "ERROR: Could not resolve a macOS SDK from $DEVELOPER_DIR" >&2
    exit 1
fi

SWIFTC="$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc"
if [[ ! -x "$SWIFTC" ]]; then
    echo "ERROR: swiftc not found at $SWIFTC" >&2
    exit 1
fi

ARCH="$(uname -m)"
case "$ARCH" in
    arm64) TARGET_TRIPLE="arm64-apple-macos13.0" ;;
    x86_64) TARGET_TRIPLE="x86_64-apple-macos13.0" ;;
    *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
esac

OUTPUT_DIR="$ROOT_DIR/.build/direct"
APP_DIR="$OUTPUT_DIR/LiveFishTTS.app"
OUTPUT="$APP_DIR/Contents/MacOS/LiveFishTTS"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/Resources/Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Resources/LucyTTS.icns" "$APP_DIR/Contents/Resources/LucyTTS.icns"
printf "APPL????" > "$APP_DIR/Contents/PkgInfo"

# shellcheck disable=SC2046
"$SWIFTC" \
    -sdk "$SDK_PATH" \
    -target "$TARGET_TRIPLE" \
    $(/usr/bin/find "$ROOT_DIR/Sources/LiveFishTTS" -name '*.swift') \
    -o "$OUTPUT"

echo "$APP_DIR"
