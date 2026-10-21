#!/usr/bin/env bash
# Login starter. Super+C uses toggle.sh and must not wait here.
set -u
AGS="$HOME/.local/bin/ags"
APP="$HOME/.config/ags/app.tsx"
UID_NOW="${UID:-$(id -u)}"
RUN="${XDG_RUNTIME_DIR:-/run/user/$UID_NOW}"
LOCK="$RUN/ags-start.lock"
LOG="$RUN/ags-run.log"

ags_pid() {
    local pid cmd
    for pid in $(pgrep -u "$UID_NOW" -x gjs || true); do
        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
        case "$cmd" in
            "gjs -m $RUN/ags.js"*) echo "$pid"; return 0 ;;
        esac
    done
    return 1
}

starting() {
    local pid cmd
    for pid in $(pgrep -u "$UID_NOW" -x ags || true); do
        cmd=$(tr '\0' ' ' < "/proc/$pid/cmdline" 2>/dev/null || true)
        case "$cmd" in
            *"/ags/app.tsx"*) return 0 ;;
        esac
    done
    return 1
}

mkdir -p "$RUN"
exec 9>"$LOCK"
flock -n 9 || exit 0
if ags_pid >/dev/null || starting; then
    exit 0
fi
setsid -f "$AGS" run "$APP" >>"$LOG" 2>&1
exit 0
