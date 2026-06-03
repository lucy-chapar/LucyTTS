#!/usr/bin/env bash
# Build and launch Lucy STT as a real .app bundle.
# Quit any running copy first so macOS loads the freshly built binary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$("$SCRIPT_DIR/build-stt.sh")"

killall LucySTT 2>/dev/null || true
sleep 0.3
open "$APP_DIR"
