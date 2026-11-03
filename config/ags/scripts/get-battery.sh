#!/usr/bin/env bash
# Prints capacity for the overlay meter.
# Refresh rate and the toast follow the mains plug, not battery charging.

BAT_PATH=(/sys/class/power_supply/BAT*)
if [ ! -e "${BAT_PATH[0]}" ]; then
    echo 0
    exit 0
fi

BAT=$(basename "${BAT_PATH[0]}")
cap=$(cat "/sys/class/power_supply/${BAT}/capacity")
echo "$cap"

online=""
found=0
for d in /sys/class/power_supply/*; do
    [ -r "$d/online" ] || continue
    t=$(cat "$d/type" 2>/dev/null || true)
    [ "$t" = "Mains" ] || continue
    found=1
    if [ "$(cat "$d/online" 2>/dev/null || true)" = 1 ]; then
        online=1
        break
    fi
    online=0
done
[ "$found" = 1 ] || exit 0

panel_hz() {
    hyprctl monitors -j 2>/dev/null | python3 -c '
import json, sys
try:
    monitors = json.load(sys.stdin)
except Exception:
    raise SystemExit(0)
for monitor in monitors:
    if monitor.get("name") == "eDP-1":
        print(round(monitor.get("refreshRate") or 0))
        break
' 2>/dev/null || true
}

stamp="${XDG_RUNTIME_DIR:-/tmp}/battery-ac-online"
want=60
[ "$online" = 1 ] && want=120
if [ ! -f "$stamp" ]; then
    printf '%s\n' "$online" >"$stamp"
    "$HOME/.config/ags/scripts/on-power-source.sh"
    exit 0
fi

prev=$(cat "$stamp" 2>/dev/null || echo "")
if [ "$prev" = "$online" ]; then
    [ "$(panel_hz)" = "$want" ] && exit 0
    POWER_HZ_ONLY=1 "$HOME/.config/ags/scripts/on-power-source.sh"
    exit 0
fi
printf '%s\n' "$online" >"$stamp"
"$HOME/.config/ags/scripts/on-power-source.sh"

if [ "$online" = 1 ]; then
    "$HOME/.config/ags/scripts/notify.sh" Battery "Plugged in" "${cap}%" >/dev/null 2>&1 &
else
    "$HOME/.config/ags/scripts/notify.sh" Battery "On battery" "${cap}%" >/dev/null 2>&1 &
fi
