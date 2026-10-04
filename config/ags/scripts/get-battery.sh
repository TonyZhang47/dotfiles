#!/usr/bin/env bash
# Prints capacity for the overlay meter.
# Toasts only on AC plug / unplug, never on Full vs Charging or low-battery.

BAT_PATH=(/sys/class/power_supply/BAT*)
if [ ! -e "${BAT_PATH[0]}" ]; then
    echo 0
    exit 0
fi

BAT=$(basename "${BAT_PATH[0]}")
cap=$(cat "/sys/class/power_supply/${BAT}/capacity")
echo "$cap"

online=""
for d in /sys/class/power_supply/*; do
    [ -r "$d/online" ] || continue
    t=$(cat "$d/type" 2>/dev/null || true)
    if [ "$t" = "Mains" ] || [ "$t" = "USB" ]; then
        online=$(cat "$d/online")
        break
    fi
done

if [ -z "$online" ]; then
    status=$(cat "/sys/class/power_supply/${BAT}/status" 2>/dev/null || echo Unknown)
    case "$status" in
        Charging|Full|"Not charging") online=1 ;;
        *) online=0 ;;
    esac
fi

stamp="${XDG_RUNTIME_DIR:-/tmp}/battery-ac-online"
if [ ! -f "$stamp" ]; then
    printf '%s\n' "$online" >"$stamp"
    exit 0
fi

prev=$(cat "$stamp" 2>/dev/null || echo "")
if [ "$prev" = "$online" ]; then
    exit 0
fi
printf '%s\n' "$online" >"$stamp"

if [ "$online" = 1 ]; then
    "$HOME/.config/ags/scripts/notify.sh" Battery "Charging" "${cap}%" >/dev/null 2>&1 &
else
    "$HOME/.config/ags/scripts/notify.sh" Battery "On battery" "${cap}%" >/dev/null 2>&1 &
fi
