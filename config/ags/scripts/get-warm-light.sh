#!/usr/bin/env bash
# true when the Super+C warm-light tile is on (hyprsunset 3500K).
if [ "$(cat "$HOME/.config/hypr/warm-light" 2>/dev/null)" = "off" ]; then
    echo false
else
    echo true
fi
