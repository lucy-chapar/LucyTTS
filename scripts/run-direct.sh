#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_PATH="$("$ROOT_DIR/scripts/build-direct.sh")"

pkill -f "LucyTTS.app/Contents/MacOS/LucyTTS" 2>/dev/null || true
open -n -F "$APP_PATH"
