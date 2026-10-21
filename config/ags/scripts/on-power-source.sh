#!/usr/bin/env bash
# Plugged in: Balanced platform profile, idle lock off.
# On battery: idle lock on. The ASUS battery profile is left as Quiet.
set -u
CONFIG="$HOME/.config/hypr/hypridle.conf"

on_ac=0
for d in /sys/class/power_supply/*; do
    [ -r "$d/online" ] || continue
    t=$(cat "$d/type" 2>/dev/null || true)
    if [ "$t" = "Mains" ] || [ "$t" = "USB" ]; then
        on_ac=$(cat "$d/online")
        break
    fi
done
if [ "$on_ac" != 1 ] && [ "$on_ac" != 0 ]; then
    status=$(head -1 /sys/class/power_supply/BAT*/status 2>/dev/null || echo Unknown)
    case "$status" in
        Charging|Full|"Not charging") on_ac=1 ;;
        *) on_ac=0 ;;
    esac
fi

if [ "$on_ac" = 1 ]; then
    asusctl profile set -a Balanced >/dev/null 2>&1 || true
    asusctl profile set Balanced >/dev/null 2>&1 || true
    if pgrep -x hypridle >/dev/null; then
        pkill -x hypridle >/dev/null 2>&1 || true
    fi
else
    if ! pgrep -x hypridle >/dev/null; then
        setsid -f hypridle -c "$CONFIG" >/dev/null 2>&1 || true
    fi
fi
