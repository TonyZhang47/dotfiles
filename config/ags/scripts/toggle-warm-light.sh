#!/usr/bin/env bash
# Super+C warm-light tile via hyprsunset (Hyprland CTM, not gammastep).
STATE="$HOME/.config/hypr/warm-light"
LOCK="${XDG_RUNTIME_DIR:-/tmp}/warm-light.lock"
export PATH="$HOME/.local/bin:$PATH"
TEMP=3500

exec 9>"$LOCK"
flock 9

"$HOME/.config/ags/scripts/ensure-hyprsunset.sh" || {
    flock -u 9
    "$HOME/.config/ags/scripts/notify.sh" "Warm light" "Warm light" "hyprsunset is not running"
    exit 1
}

current=$(cat "$STATE" 2>/dev/null || echo on)
if [ "$current" != "off" ]; then
    want=off
    flag=false
    label=Off
else
    want=on
    flag=true
    label=On
fi
printf '%s\n' "$want" >"$STATE"

# Drop any leftover screen-shader from the old toggle so CTM is the only filter.
hyprctl eval 'hl.config({ decoration = { screen_shader = "" } })' >/dev/null 2>&1 || true

if [ "$want" = on ]; then
    hyprctl hyprsunset temperature "$TEMP" >/dev/null
else
    hyprctl hyprsunset identity >/dev/null
fi

flock -u 9
"$HOME/.config/ags/scripts/notify.sh" "Warm light" "Warm light" "$label"
