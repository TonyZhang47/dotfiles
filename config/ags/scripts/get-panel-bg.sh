#!/usr/bin/env bash
# The current widget background colour, read from the palette matugen generates.
# The wallpaper picker polls this so it starts in the right colour after a reload,
# since reloading resets variables to their initial value.
COLORS="$HOME/.config/ags/colors.scss"
[ -f "$COLORS" ] || { echo "#1e1e2e"; exit 0; }
awk '/^\$background:/ { gsub(/;/, "", $2); print $2; exit }' "$COLORS"
