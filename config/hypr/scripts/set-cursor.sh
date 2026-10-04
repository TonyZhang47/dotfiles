#!/usr/bin/env bash
# Apply Bibata as soon as Hyprland's socket is up. A single hyprctl
# setcursor on hyprland.start often races and leaves the Adwaita default
# until some later input (volume/brightness) recreates the cursor.
THEME="Bibata-Modern-Ice"
SIZE=20

gsettings set org.gnome.desktop.interface cursor-theme "$THEME" >/dev/null 2>&1 || true
gsettings set org.gnome.desktop.interface cursor-size "$SIZE" >/dev/null 2>&1 || true

for _ in 1 2 3 4 5 6 8 10 12; do
    if hyprctl setcursor "$THEME" "$SIZE" >/dev/null 2>&1; then
        exit 0
    fi
    sleep 0.4
done
exit 1
