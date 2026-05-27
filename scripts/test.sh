#!/usr/bin/env bash
# Run the Lucy TTS test suite.
# Auto-selects Xcode so this works on any machine with Xcode installed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=scripts/_select_xcode.sh
source "$SCRIPT_DIR/_select_xcode.sh"
select_xcode

cd "$ROOT_DIR"
exec swift test "$@"
