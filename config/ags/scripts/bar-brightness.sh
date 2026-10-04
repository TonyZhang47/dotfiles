#!/usr/bin/env bash
# Brightness for the bar: scroll to change.
case "$1" in
    up)   brightnessctl -q s +5% ;;
    down) brightnessctl -q s 5%- ;;
esac
