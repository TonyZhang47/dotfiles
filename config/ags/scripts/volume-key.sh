#!/usr/bin/env bash
# Laptop volume keys. Repeats are coalesced into one toast.
case "${1:-}" in
    up) wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    *) exit 1 ;;
esac

raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@)
level=$(printf '%s\n' "$raw" | awk '{printf "%d", $2 * 100}')
if printf '%s\n' "$raw" | grep -q MUTED; then
    "$HOME/.config/ags/scripts/notify.sh" --throttle volume Volume "Muted" "${level}%"
else
    "$HOME/.config/ags/scripts/notify.sh" --throttle volume Volume "Volume" "${level}%"
fi
