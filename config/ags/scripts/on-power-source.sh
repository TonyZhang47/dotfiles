#!/usr/bin/env bash
# Plugged in: Balanced platform profile, 120 Hz, idle lock off.
# Unplugged: 60 Hz, idle lock on. The ASUS battery profile is left as Quiet.
# The plug decides this. Charging, full, and the 60% charge cap do not.
set -u
FULL="$HOME/.config/hypr/hypridle.conf"
SLEEP="$HOME/.config/hypr/hypridle-sleep.conf"

# Returns 0 when a mains adapter is plugged in, 1 when every mains
# adapter is unplugged, and 2 when no mains adapter can be read.
plugged_in() {
    local d t online found=0
    for d in /sys/class/power_supply/*; do
        [ -r "$d/online" ] || continue
        t=$(cat "$d/type" 2>/dev/null || true)
        [ "$t" = "Mains" ] || continue
        online=$(cat "$d/online" 2>/dev/null || true)
        found=1
        [ "$online" = 1 ] && return 0
    done
    [ "$found" = 1 ] && return 1
    return 2
}

set_panel_hz() {
    local want="$1"
    local cur=""
    cur=$(hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
for monitor in monitors:
    if monitor.get("name") == "eDP-1":
        print(round(monitor.get("refreshRate") or 0))
        break
' 2>/dev/null || true)
    [ "$cur" = "$want" ] && return 0
    hyprctl eval "hl.monitor({ output = \"eDP-1\", mode = \"2880x1800@${want}\", position = \"auto\", scale = 1.5 })" >/dev/null 2>&1 || true
}

start_idle() {
    pkill -x hypridle >/dev/null 2>&1 || true
    sleep 0.2
    setsid -f hypridle -c "$1" >/dev/null 2>&1 || true
}

plugged_in
case $? in
    0) on_ac=1 ;;
    1) on_ac=0 ;;
    *) exit 0 ;;
esac

if [ "$on_ac" = 1 ]; then
    set_panel_hz 120
    [ "${POWER_HZ_ONLY:-0}" = 1 ] && exit 0
    asusctl profile set -a Balanced >/dev/null 2>&1 || true
    asusctl profile set Balanced >/dev/null 2>&1 || true
    # Idle dim and lock stay off on AC. The sleep helper still locks the
    # screen when the lid closes and turns it back on after wake.
    start_idle "$SLEEP"
else
    set_panel_hz 60
    [ "${POWER_HZ_ONLY:-0}" = 1 ] && exit 0
    start_idle "$FULL"
fi
