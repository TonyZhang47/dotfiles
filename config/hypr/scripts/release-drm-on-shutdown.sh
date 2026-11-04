#!/bin/bash
# Hold a logind shutdown delay until Hyprland has dropped nvidia_drm.
# asus-shutdown writes dgpu_disable after a short idle wait. If Hyprland
# still owns the DRM device when that write removes the GPU, nvidia_modeset
# page-faults and the console fills with a kernel oops.
set -u
export PATH="/usr/bin:/usr/sbin:/bin:/sbin"

release_drm() {
    local sig i users
    sig=$(ls -1 "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/hypr" 2>/dev/null | head -n 1 || true)
    if [ -n "$sig" ] && command -v hyprctl >/dev/null 2>&1; then
        HYPRLAND_INSTANCE_SIGNATURE="$sig" hyprctl dispatch exit >/dev/null 2>&1 || true
    fi
    pkill -TERM -x Hyprland >/dev/null 2>&1 || true
    pkill -TERM -x hyprpolkitagent >/dev/null 2>&1 || true
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 \
             21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40; do
        users=$(awk '/^nvidia_drm / { print $3; exit }' /proc/modules 2>/dev/null || true)
        if [ -z "$users" ] || [ "$users" = "0" ]; then
            return 0
        fi
        sleep 0.25
    done
}

if [ "${1:-}" != "--hold" ]; then
    exec systemd-inhibit \
        --what=shutdown \
        --mode=delay \
        --who="Hyprland" \
        --why="Close the desktop before the NVIDIA GPU is powered off" \
        "$0" --hold
fi

on_signal() {
    local preparing
    preparing=$(busctl --system --json=short get-property \
        org.freedesktop.login1 /org/freedesktop/login1 \
        org.freedesktop.login1.Manager PreparingForShutdown 2>/dev/null || true)
    case "$preparing" in
        *'"data":true'*) release_drm ;;
    esac
    exit 0
}
trap on_signal TERM INT

while true; do
    out=$(busctl --system --json=short wait \
        /org/freedesktop/login1 org.freedesktop.login1.Manager PrepareForShutdown) || exit 1
    case "$out" in
        *'"data":[true]'*)
            release_drm
            exit 0
            ;;
    esac
done
