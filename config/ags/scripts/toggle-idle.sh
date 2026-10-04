#!/bin/bash
# Start hypridle if it is not running, otherwise stop it.
CONFIG="$HOME/.config/hypr/hypridle.conf"

if pgrep -x hypridle >/dev/null; then
    pkill -x hypridle
    "$HOME/.config/ags/scripts/notify.sh" Idle "Idle lock" "Off"
else
    setsid -f hypridle -c "$CONFIG" >/dev/null 2>&1
    "$HOME/.config/ags/scripts/notify.sh" Idle "Idle lock" "On"
fi
