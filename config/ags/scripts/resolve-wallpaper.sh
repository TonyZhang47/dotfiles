#!/usr/bin/env bash
# Print the full path of a wallpaper.
#   stem            -> ~/.config/wallpapers (Super+G, static)
#   static:stem     -> ~/.config/wallpapers
#   live:stem       -> ~/.config/live-wallpapers
# Optional $2 is a directory override for unprefixed names.
NAME="$1"
DIR_OVERRIDE="${2:-}"
STATIC="$HOME/.config/wallpapers"
LIVE="$HOME/.config/live-wallpapers"
[ -n "$NAME" ] || exit 1

find_in() {
    local dir="$1" stem="$2"
    shift 2
    local ext candidate
    for ext in "$@"; do
        candidate="$dir/$stem.$ext"
        if [ -f "$candidate" ]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done
    return 1
}

STATIC_EXTS=(jpg jpeg png webp JPG JPEG PNG WEBP)
LIVE_EXTS=(gif GIF webp WEBP)

if [[ "$NAME" == live:* ]]; then
    find_in "$LIVE" "${NAME#live:}" "${LIVE_EXTS[@]}"
elif [[ "$NAME" == static:* ]]; then
    find_in "$STATIC" "${NAME#static:}" "${STATIC_EXTS[@]}"
else
    dir="${DIR_OVERRIDE:-$STATIC}"
    if [ "$dir" = "$LIVE" ]; then
        find_in "$LIVE" "$NAME" "${LIVE_EXTS[@]}"
    else
        find_in "$STATIC" "$NAME" "${STATIC_EXTS[@]}"
    fi
fi
