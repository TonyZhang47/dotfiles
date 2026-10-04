#!/usr/bin/env bash
case "${1:-}" in
    up) brightnessctl -d amdgpu_bl1 set 5%+ >/dev/null ;;
    down) brightnessctl -d amdgpu_bl1 set 5%- >/dev/null ;;
    *) exit 1 ;;
esac
pct=$(brightnessctl -d amdgpu_bl1 -m | awk -F, '{gsub(/%/,"",$4); print $4}')
"$HOME/.config/ags/scripts/notify.sh" --throttle brightness Brightness "Brightness" "${pct}%"
