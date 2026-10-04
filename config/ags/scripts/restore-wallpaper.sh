#!/bin/bash

STATE="$HOME/.config/wallpapers/.current"
FALLBACK="$HOME/.config/wallpapers/7.jpg"
WP="$FALLBACK"

if [ -f "$STATE" ]; then
    saved=$(head -n 1 "$STATE")
    if [ -n "$saved" ] && [ -f "$saved" ]; then
        WP="$saved"
    fi
fi

if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon >/dev/null 2>&1 &
    sleep 0.4
fi

awww img "$WP" --resize crop >/dev/null 2>&1 || {
    sleep 0.5
    awww img "$WP" --resize crop >/dev/null 2>&1
}
