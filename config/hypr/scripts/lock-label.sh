#!/usr/bin/env bash
# Text for hyprlock labels. argv: day | time | cava
case "${1:-}" in
    day)
        # Rainmeter-style weekday: Comfortaa Light + wide tracking.
        d=$(date +%A | tr '[:upper:]' '[:lower:]')
        printf '<span font_family="Comfortaa" font_weight="300" letter_spacing="11000">%s</span>\n' "$d"
        ;;
    time)
        date +"- %I:%M%p -"
        ;;
    cava)
        f="${XDG_RUNTIME_DIR:-/tmp}/hyprlock-cava"
        if [ -s "$f" ]; then
            cat "$f"
        else
            printf '▁%.0s' {1..42}
            printf '\n'
        fi
        ;;
esac
