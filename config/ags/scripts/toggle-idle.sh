#!/bin/bash
# Toggle idle dim/lock/sleep. A sleep-only helper stays running either way
# so closing the lid still locks and the screen comes back on wake.
FULL="$HOME/.config/hypr/hypridle.conf"
SLEEP="$HOME/.config/hypr/hypridle-sleep.conf"

start_sleep_only() {
    setsid -f hypridle -c "$SLEEP" >/dev/null 2>&1 || true
}

if pgrep -a -x hypridle | grep -q -F '/hypr/hypridle.conf'; then
    pkill -x hypridle
    sleep 0.2
    start_sleep_only
    "$HOME/.config/ags/scripts/notify.sh" Idle "Idle lock" "Off"
else
    pkill -x hypridle
    sleep 0.2
    setsid -f hypridle -c "$FULL" >/dev/null 2>&1
    "$HOME/.config/ags/scripts/notify.sh" Idle "Idle lock" "On"
fi
