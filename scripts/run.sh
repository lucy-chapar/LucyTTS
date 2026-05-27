#!/usr/bin/env bash
# Launch Lucy TTS on macOS as a proper .app bundle so keyboard focus and
# menu behavior match a real install (instead of `swift run` from terminal,
# which can break native text input).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "$SCRIPT_DIR/run-direct.sh" "$@"
