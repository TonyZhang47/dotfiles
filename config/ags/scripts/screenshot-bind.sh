#!/usr/bin/env bash
# Super+S copies a region. Super+Shift+S also saves it.
# Same tool as the control-center menu, so the toast matches.
set -u
mkdir -p "$HOME/Pictures/Screenshots"
case "${1:-clip}" in
    clip) exec hyprshot -m region --clipboard-only ;;
    save) exec hyprshot -m region -o "$HOME/Pictures/Screenshots" ;;
    *) exit 1 ;;
esac
