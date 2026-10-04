#!/usr/bin/env bash
wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; then
    "$HOME/.config/ags/scripts/notify.sh" Microphone "Microphone" "Muted"
else
    "$HOME/.config/ags/scripts/notify.sh" Microphone "Microphone" "On"
fi
