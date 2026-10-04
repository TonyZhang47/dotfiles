#!/usr/bin/env bash
# Super+L. Start the lock-screen visualizer, then hyprlock.
export PATH="$HOME/.local/bin:$PATH"
pidof hyprlock >/dev/null && exit 0

CAVA_PID=""
if command -v cava >/dev/null 2>&1; then
    mkdir -p "${XDG_RUNTIME_DIR:-/tmp}"
    setsid -f "$HOME/.config/hypr/scripts/lock-cava.sh" >/dev/null 2>&1 &
    CAVA_PID=$!
fi

cleanup() {
    if [ -n "$CAVA_PID" ]; then
        kill "$CAVA_PID" >/dev/null 2>&1 || true
        pkill -f '/hypr/scripts/lock-cava.sh' >/dev/null 2>&1 || true
        pkill -f 'cava -p .*/cava/hyprlock' >/dev/null 2>&1 || true
    fi
}
trap cleanup EXIT

hyprlock -c "$HOME/.config/hypr/hyprlock.conf"
