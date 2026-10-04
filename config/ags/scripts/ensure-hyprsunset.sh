#!/usr/bin/env bash
# Start hyprsunset if needed, then wait until hyprctl can talk to it.
export PATH="$HOME/.local/bin:$PATH"
BIN="${HOME}/.local/bin/hyprsunset"
[ -x "$BIN" ] || BIN=$(command -v hyprsunset || true)
[ -n "$BIN" ] || exit 1

if ! hyprctl hyprsunset temperature >/dev/null 2>&1; then
    systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DISPLAY XDG_RUNTIME_DIR >/dev/null 2>&1 || true
    if ! systemctl --user start hyprsunset.service >/dev/null 2>&1; then
        pgrep -x hyprsunset >/dev/null || setsid -f "$BIN" >/dev/null 2>&1
    fi
    for _ in $(seq 1 20); do
        hyprctl hyprsunset temperature >/dev/null 2>&1 && break
        sleep 0.1
    done
fi
hyprctl hyprsunset temperature >/dev/null 2>&1
