#!/usr/bin/env bash
# Build Lucy STT into a standalone .app bundle.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=scripts/_select_xcode.sh
source "$SCRIPT_DIR/_select_xcode.sh"
select_xcode

SDK_PATH="${SDKROOT:-}"
if [[ -z "$SDK_PATH" ]]; then
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
APP_DIR="$OUTPUT_DIR/LucySTT.app"
OUTPUT="$APP_DIR/Contents/MacOS/LucySTT"

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"
cp "$ROOT_DIR/Resources/LucySTT-Info.plist" "$APP_DIR/Contents/Info.plist"
cp "$ROOT_DIR/Resources/LucyTTS.icns" "$APP_DIR/Contents/Resources/LucyTTS.icns"
printf "APPL????" > "$APP_DIR/Contents/PkgInfo"

# shellcheck disable=SC2046
"$SWIFTC" \
    -sdk "$SDK_PATH" \
    -target "$TARGET_TRIPLE" \
    $(/usr/bin/find "$ROOT_DIR/Sources/LucySTT" -name '*.swift') \
    -o "$OUTPUT"

echo "$APP_DIR"
