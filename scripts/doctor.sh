#!/usr/bin/env bash
# Print a snapshot of the build toolchain so you (or an agent) can quickly see
# whether the environment is healthy. Exits 0 if a usable Xcode was found,
# non-zero if not.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf '== Lucy TTS toolchain doctor ==\n\n'

printf 'macOS version : '
sw_vers -productVersion 2>/dev/null || echo 'unknown'

printf 'Architecture  : '
uname -m

printf 'xcode-select  : '
/usr/bin/xcode-select -p 2>/dev/null || echo 'not set'

if [[ -n "${DEVELOPER_DIR:-}" ]]; then
    printf 'DEVELOPER_DIR : %s (inherited from environment)\n' "$DEVELOPER_DIR"
else
    printf 'DEVELOPER_DIR : (not set in this shell)\n'
fi

printf '\n'

# shellcheck source=scripts/_select_xcode.sh
source "$SCRIPT_DIR/_select_xcode.sh"

if select_xcode; then
    printf '\nResolved Xcode\n'
    printf '  DEVELOPER_DIR : %s\n' "$DEVELOPER_DIR"
    printf '  xcodebuild    : '
    "$DEVELOPER_DIR/usr/bin/xcodebuild" -version 2>/dev/null | head -n1 || echo 'unavailable'
    printf '  swift         : '
    "$DEVELOPER_DIR/Toolchains/XcodeDefault.xctoolchain/usr/bin/swift" --version 2>/dev/null | head -n1 || echo 'unavailable'
    printf '\nAll good. Use `make build`, `make test`, `make run`, or `make ios-build`.\n'
    exit 0
fi

printf '\nNo usable Xcode found. See the message above.\n'
exit 1
