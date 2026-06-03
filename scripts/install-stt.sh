#!/usr/bin/env bash
# Build Lucy STT and install it to /Applications.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$("$SCRIPT_DIR/build-stt.sh")"
INSTALL_PATH="/Applications/Lucy STT.app"

killall LucySTT 2>/dev/null || true
rm -rf "$INSTALL_PATH"
ditto "$APP_DIR" "$INSTALL_PATH"

echo "Installed Lucy STT to $INSTALL_PATH"
open "$INSTALL_PATH"
