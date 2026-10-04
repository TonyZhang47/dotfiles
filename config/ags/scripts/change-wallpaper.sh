#!/bin/bash

SELECTED_WALLPAPER=$1
MODE=$2

if ~/.config/ags/scripts/resolve-wallpaper.sh "$SELECTED_WALLPAPER" >/dev/null; then
    ~/.config/ags/scripts/update-color.sh "$SELECTED_WALLPAPER" "$MODE"
else
    echo "Wallpaper not found: $SELECTED_WALLPAPER"
    exit 1
fi
