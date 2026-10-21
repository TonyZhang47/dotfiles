#!/usr/bin/env bash
# Super+C / Super+H / Super+Shift+T.
# Tell AGS via a runtime file. Never call `ags list` / `ags toggle` — those hang.
set -u
WIN="${1:?window name}"
AGS="$HOME/.local/bin/ags"
APP="$HOME/.config/ags/app.tsx"
UID_NOW="${UID:-$(id -u)}"
RUN="${XDG_RUNTIME_DIR:-/run/user/$UID_NOW}"
FLAG="$RUN/ags-toggle"
READY="$RUN/ags-ready"
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

start_ags() {
    mkdir -p "$RUN"
    exec 9>"$LOCK"
    flock -n 9 || return 0
    if ! ags_pid >/dev/null && ! starting; then
        setsid -f "$AGS" run "$APP" >>"$LOG" 2>&1
    fi
}

ask() {
    mkdir -p "$RUN"
    printf '%s %s\n' "$WIN" "$$-$(date +%s%N)" >"$FLAG"
}

ping_ags() {
    timeout 0.4 "$AGS" request "$WIN" >/dev/null 2>&1
}

if ! ags_pid >/dev/null; then
    rm -f "$READY"
    start_ags
fi

i=0
while [ "$i" -lt 80 ]; do
    [ -f "$READY" ] && break
    sleep 0.1
    i=$((i + 1))
done

# Prefer AGS request (works once requestHandler is up). File is the fallback
# if that IPC ever stalls again.
if ping_ags; then
    exit 0
fi
ask
exit 0
