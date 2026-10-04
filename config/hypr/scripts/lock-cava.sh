#!/usr/bin/env bash
# Write cava bars for hyprlock. Only runs while the lock screen is up.
OUT="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-cava"
CFG="$HOME/.config/cava/hyprlock"
BARS="▁▂▃▄▅▆▇█"
IDLE="$(printf '▁%.0s' {1..42})"

printf '%s\n' "$IDLE" >"$OUT"

exec cava -p "$CFG" 2>/dev/null | while IFS= read -r line; do
    out=""
    for n in $line; do
        case "$n" in
            ''|*[!0-9]*) n=0 ;;
        esac
        [ "$n" -gt 7 ] && n=7
        out="${out}${BARS:$n:1}"
    done
    if [ -z "$out" ]; then
        out="$IDLE"
    fi
    printf '%s\n' "$out" >"$OUT"
done
