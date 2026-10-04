#!/usr/bin/env bash
# Desktop toasts (mako). Same popup the control-center screenshot uses.
#   notify.sh [--throttle key] App "Title" "Body" [icon-path]
export PATH="$HOME/.local/bin:$PATH"

if [ "${1:-}" = "--throttle" ]; then
    key=${2:?}
    shift 2
    dir="${XDG_RUNTIME_DIR:-/tmp}/osd-notify"
    mkdir -p "$dir"
    printf '%s\0' "$@" >"$dir/$key.payload"
    if [ ! -f "$dir/$key.lock" ]; then
        : >"$dir/$key.lock"
        (
            sleep 0.3
            mapfile -d '' -t args <"$dir/$key.payload" || true
            rm -f "$dir/$key.lock"
            [ ${#args[@]} -ge 2 ] || exit 0
            exec "$HOME/.config/ags/scripts/notify.sh" "${args[@]}"
        ) &
    fi
    exit 0
fi

app=${1:-Desktop}
summary=${2:-}
body=${3:-}
icon=${4:-}

if [ -n "$icon" ] && [ -e "$icon" ]; then
    notify-send -a "$app" -i "$icon" -- "$summary" "$body"
else
    notify-send -a "$app" -- "$summary" "$body"
fi
