#!/usr/bin/env bash
# Build the LucyTTSiOS target for the iOS Simulator as a smoke test.
# Does not install or launch anything; pass `-destination` overrides as args
# if you want to target a specific simulator.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# shellcheck source=scripts/_select_xcode.sh
source "$SCRIPT_DIR/_select_xcode.sh"
select_xcode

cd "$ROOT_DIR"
exec xcodebuild \
    -project LucyTTS.xcodeproj \
    -scheme LucyTTSiOS \
    -destination 'generic/platform=iOS Simulator' \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    DEVELOPMENT_TEAM="" \
    build \
    "$@"
