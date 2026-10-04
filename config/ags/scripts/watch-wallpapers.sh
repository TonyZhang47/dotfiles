#!/usr/bin/env bash
# Watch static and live wallpaper folders; sync previews + theme caches on add/delete.
STATIC="$HOME/.config/wallpapers"
LIVE="$HOME/.config/live-wallpapers"
SYNC="$HOME/.config/ags/scripts/sync-wallpapers.sh"
mkdir -p "$STATIC" "$LIVE"

"$SYNC" >/dev/null 2>&1 || true

command -v inotifywait >/dev/null 2>&1 || exit 0

inotifywait -m -q \
    -e close_write,moved_to,delete,moved_from,create \
    --format '%w %e %f' \
    "$STATIC" "$LIVE" |
while read -r dir events name; do
    case "$name" in
        preview-*|.current|README|README.txt|.*|"") continue ;;
    esac
    sleep 0.35
    "$SYNC" >/dev/null 2>&1 || true
done
