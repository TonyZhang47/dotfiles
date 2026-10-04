#!/usr/bin/env bash
case "${1:-}" in
    next) playerctl next ;;
    prev) playerctl previous ;;
    toggle) playerctl play-pause ;;
    *) exit 1 ;;
esac
sleep 0.15
status=$(playerctl status 2>/dev/null || true)
title=$(playerctl metadata --format '{{title}}' 2>/dev/null || true)
artist=$(playerctl metadata --format '{{artist}}' 2>/dev/null || true)
cover=$(playerctl metadata --format '{{mpris:artUrl}}' 2>/dev/null || true)
icon=""
if [ -n "$cover" ]; then
    case "$cover" in
        file://*) icon=${cover#file://} ;;
    esac
fi
body="$title"
[ -n "$artist" ] && body="$title — $artist"
case "$status" in
    Playing) "$HOME/.config/ags/scripts/notify.sh" Music "Playing" "$body" "$icon" ;;
    Paused)  "$HOME/.config/ags/scripts/notify.sh" Music "Paused" "$body" "$icon" ;;
    *)       "$HOME/.config/ags/scripts/notify.sh" Music "Music" "${body:-No player}" "$icon" ;;
esac
