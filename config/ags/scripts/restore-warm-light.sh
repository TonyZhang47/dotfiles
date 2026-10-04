#!/usr/bin/env bash
# Apply saved warm/cool state after hyprsunset starts.
export PATH="$HOME/.local/bin:$PATH"
STATE="$HOME/.config/hypr/warm-light"
"$HOME/.config/ags/scripts/ensure-hyprsunset.sh" || exit 0
# Clear the old screen-shader path if a reload left it set.
hyprctl eval 'hl.config({ decoration = { screen_shader = "" } })' >/dev/null 2>&1 || true
if [ "$(cat "$STATE" 2>/dev/null || echo on)" = "off" ]; then
    hyprctl hyprsunset identity >/dev/null
else
    hyprctl hyprsunset temperature 3500 >/dev/null
fi
