#!/usr/bin/env bash
# Apply the bundled theme to an authorized TV with CleanYourTV already installed.
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }
if [[ ${1:-} == --help ]]; then
    printf 'Usage: bash install-theme.sh [TV_ADDRESS[:PORT] | connected-serial]\n'
    exit 0
fi
(( $# <= 1 )) || fail "Usage: bash install-theme.sh [TV_ADDRESS[:PORT] | connected-serial]"
command -v adb >/dev/null || fail "Install Android SDK Platform-Tools and make adb available on PATH."

bundle=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
theme="$bundle/theme"
[[ -s "$theme/config.json" ]] || fail "Missing theme/config.json."
shopt -s nullglob
photos=("$theme"/wallpapers/*)
(( ${#photos[@]} > 0 )) || fail "The theme contains no wallpapers."
for photo in "${photos[@]}"; do
    name=${photo##*/}
    [[ -f "$photo" && "$name" =~ ^[A-Za-z0-9_.-]+$ ]] || fail "Unsupported wallpaper filename: $name"
    [[ "$name" =~ \.[jJ][pP][eE]?[gG]$|\.[pP][nN][gG]$|\.[wW][eE][bB][pP]$ ]] || fail "Unsupported wallpaper format: $name"
    size=$(wc -c < "$photo")
    (( size > 0 && size <= 10485760 )) || fail "Wallpaper must be between 1 byte and 10 MiB: $name"
done

device=(adb)
if [[ -n ${1:-} ]]; then
    target=$1
    [[ "$target" != -* ]] || fail "Supply an ADB address or serial."
    if [[ $(adb -s "$target" get-state 2>/dev/null || true) != device ]]; then
        endpoint=$target
        if [[ "$target" != *:* ]]; then endpoint="$target:5555"; fi
        adb connect "$endpoint"
        target=$endpoint
    fi
    device+=(-s "$target")
fi
[[ $("${device[@]}" get-state 2>/dev/null || true) == device ]] ||
    fail "Connect one TV and accept its ADB authorization prompt, then retry."

tv() { "${device[@]}" "$@"; }
package=com.gathin.tvhome
home=$(tv shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tr -d '\r')
[[ "$home" == *"$package/"* ]] || fail "Set CleanYourTV as the TV's Home app first."

root="/sdcard/Android/data/$package/files"
stamp="$(date +%Y%m%d-%H%M%S)-$$"
stage="$root/.theme-incoming-$stamp"
backup="$root/theme-backup-$stamp"
tv shell "mkdir -p '$root' && mkdir '$stage' && mkdir '$stage/wallpapers'" ||
    fail "ADB cannot write to CleanYourTV's theme directory on this TV."
cleanup() { tv shell "rm -rf '$stage'" >/dev/null 2>&1 || true; }
trap cleanup EXIT
tv push "$theme/config.json" "$stage/config.json" >/dev/null
for photo in "${photos[@]}"; do tv push "$photo" "$stage/wallpapers/${photo##*/}" >/dev/null; done

tv shell "set -e
    cd '$root'
    mkdir 'theme-backup-$stamp'
    for item in config.json wallpaper.jpg wallpapers; do
        if [ -e \"\$item\" ]; then
            if ! mv \"\$item\" 'theme-backup-$stamp/'; then
                for saved in 'theme-backup-$stamp/'*; do
                    [ ! -e \"\$saved\" ] || mv \"\$saved\" ./
                done
                exit 1
            fi
        fi
    done
    if ! (mv '.theme-incoming-$stamp/config.json' config.json &&
          mv '.theme-incoming-$stamp/wallpapers' wallpapers); then
        [ ! -e config.json ] || mv config.json '.theme-incoming-$stamp/'
        [ ! -e wallpapers ] || mv wallpapers '.theme-incoming-$stamp/'
        for saved in 'theme-backup-$stamp/'*; do
            [ ! -e \"\$saved\" ] || mv \"\$saved\" ./
        done
        exit 1
    fi"
printf 'Installed %s wallpapers. Previous theme files are saved on the TV at %s\n' "${#photos[@]}" "$backup"
tv shell am start -W -f 0x10008000 -a android.intent.action.MAIN -c android.intent.category.HOME \
    -n "$package/.MainActivity" || fail "Theme files are installed. Reopen CleanYourTV to load them."
