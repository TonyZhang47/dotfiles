#!/bin/bash
# Names of every live wallpaper (gif/webp), for Super+Shift+T.

DIRECTORY="$HOME/.config/live-wallpapers"
names=()

mkdir -p "$DIRECTORY"
shopt -s nullglob
for file in "$DIRECTORY"/*.{gif,GIF,webp,WEBP}; do
    [ -e "$file" ] || continue
    base=$(basename "$file")
    case "$base" in
        preview-*) continue ;;
    esac
    names+=("${base%.*}")
done

IFS=$'\n' names=($(printf '%s\n' "${names[@]}" | sort -Vu))

first=1
printf '['
for line in "${names[@]}"; do
    [ -n "$line" ] || continue
    if [ "$first" -eq 1 ]; then
        first=0
    else
        printf ','
    fi
    printf '"%s"' "$line"
done
printf ']\n'
