#!/usr/bin/env bash
# Sourced helper that locates a real Xcode installation and exports
# DEVELOPER_DIR so subsequent `swift` / `xcodebuild` / `xcrun` calls work
# regardless of what `xcode-select -p` happens to point at.
#
# Usage:
#     # shellcheck disable=SC1091
#     source "$(dirname "$0")/_select_xcode.sh"
#
# On success: DEVELOPER_DIR is exported and the function returns 0.
# On failure: prints a clear error to stderr and returns 1.
#
# Detection order (first match wins):
#   1. $DEVELOPER_DIR if it already points at a valid Xcode.app/Contents/Developer
#   2. `xcode-select -p` if it points at a real Xcode (not Command Line Tools)
#   3. /Applications/Xcode*.app
#   4. $HOME/Applications/Xcode*.app
#   5. Spotlight (mdfind) lookup of any installed Xcode bundle

_lucytts_xcode_is_valid() {
    local dev_dir="$1"
    [[ -n "$dev_dir" ]] || return 1
    [[ -x "$dev_dir/usr/bin/xcodebuild" ]] || return 1
    [[ "$dev_dir" != *CommandLineTools* ]] || return 1
    return 0
}

_lucytts_pick_newest_xcode() {
    # Reads Xcode.app paths on stdin (one per line), prints the path of the
    # newest installed Xcode (by CFBundleShortVersionString) to stdout.
    local best_path=""
    local best_version="0"
    while IFS= read -r app_path; do
        [[ -n "$app_path" ]] || continue
        local version_plist="$app_path/Contents/version.plist"
        local version="0"
        if [[ -f "$version_plist" ]]; then
            version="$(/usr/bin/defaults read "$version_plist" CFBundleShortVersionString 2>/dev/null || echo "0")"
        fi
        if [[ -z "$best_path" ]] || \
           [[ "$(printf '%s\n%s\n' "$best_version" "$version" | sort -V | tail -n1)" == "$version" ]]; then
            best_path="$app_path"
            best_version="$version"
        fi
    done
    [[ -n "$best_path" ]] && printf '%s\n' "$best_path"
}

select_xcode() {
    if [[ -n "${DEVELOPER_DIR:-}" ]] && _lucytts_xcode_is_valid "$DEVELOPER_DIR"; then
        export DEVELOPER_DIR
        return 0
    fi

    local current_select
    current_select="$(/usr/bin/xcode-select -p 2>/dev/null || true)"
    if _lucytts_xcode_is_valid "$current_select"; then
        export DEVELOPER_DIR="$current_select"
        return 0
    fi

    local candidates=()
    local app
    for app in /Applications/Xcode*.app "$HOME/Applications/Xcode"*.app; do
        [[ -d "$app" ]] && candidates+=("$app")
    done

    if [[ ${#candidates[@]} -eq 0 ]] && command -v mdfind >/dev/null 2>&1; then
        while IFS= read -r app; do
            [[ -d "$app" ]] && candidates+=("$app")
        done < <(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null)
    fi

    if [[ ${#candidates[@]} -eq 0 ]]; then
        cat >&2 <<'EOF'
ERROR: Could not find an Xcode installation.

Lucy TTS needs Xcode (not just the Command Line Tools) to build.

  1. Install Xcode from the Mac App Store, or download it from
     https://developer.apple.com/download/all/
  2. Launch Xcode once so it finishes installing components.
  3. Re-run this command.

If Xcode is installed somewhere unusual, set DEVELOPER_DIR explicitly:

  export DEVELOPER_DIR="/path/to/Xcode.app/Contents/Developer"
EOF
        return 1
    fi

    local chosen
    chosen="$(printf '%s\n' "${candidates[@]}" | _lucytts_pick_newest_xcode)"

    if [[ -z "$chosen" ]] || ! _lucytts_xcode_is_valid "$chosen/Contents/Developer"; then
        echo "ERROR: Found Xcode at '$chosen' but it does not appear usable." >&2
        return 1
    fi

    export DEVELOPER_DIR="$chosen/Contents/Developer"
    return 0
}
