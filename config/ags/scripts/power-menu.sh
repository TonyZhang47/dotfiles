#!/usr/bin/env bash
# Power menu for the bar button. The icons need a nerd font.

ENTRIES="  Lock
  Suspend
  Log out
  Reboot
  Shut down"

CHOSEN=$(printf '%s\n' "$ENTRIES" | rofi -dmenu -i -config ~/.config/rofi/config-power.rasi -p "")

# Dismissing the menu has to do nothing at all, so match on the label and never
# fall through to an action.
case "$CHOSEN" in
    *"Lock")      hyprlock ;;
    *"Suspend")   systemctl suspend ;;
    *"Log out")   hyprctl dispatch "hl.dsp.exit()" ;;
    *"Reboot")    systemctl reboot ;;
    *"Shut down") systemctl poweroff ;;
esac
