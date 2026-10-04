#!/bin/bash
export PATH="$HOME/.local/bin:$PATH"

run_if_exists() {
    if command -v "$1" >/dev/null 2>&1; then
        "$@"
    else
        echo "Skip: Command $1 not found."
    fi
}

SELECTED_WALLPAPER=$1
RELOAD_APPS=$2
WP_PATH=$("$HOME/.config/ags/scripts/resolve-wallpaper.sh" "$SELECTED_WALLPAPER") || {
    echo "Error: Wallpaper not found: $SELECTED_WALLPAPER"
    exit 1
}

NOTIFY_NAME="${SELECTED_WALLPAPER#live:}"
NOTIFY_NAME="${NOTIFY_NAME#static:}"

still_for() {
    local src="$1" ext stem preview dest
    ext=$(echo "${src##*.}" | tr 'A-Z' 'a-z')
    if [ "$ext" != gif ]; then
        printf '%s\n' "$src"
        return 0
    fi
    stem=$(basename "$src")
    stem="${stem%.*}"
    preview="$HOME/.config/live-wallpapers/preview-${stem}.jpg"
    if [ -f "$preview" ]; then
        printf '%s\n' "$preview"
        return 0
    fi
    dest="$HOME/.cache/matugen/live-frames/${stem}.jpg"
    mkdir -p "$(dirname "$dest")"
    if command -v magick >/dev/null 2>&1 && magick "${src}[0]" "$dest" 2>/dev/null; then
        printf '%s\n' "$dest"
        return 0
    fi
    printf '%s\n' "$src"
}
STILL=$(still_for "$WP_PATH")

if ! pgrep -x awww-daemon >/dev/null && ! pgrep -x awww >/dev/null; then
    awww-daemon >/dev/null 2>&1 &
    sleep 0.3
fi
# Fade at the panel refresh rate, and wait until it finishes.
# Generating colors during the fade drops frames.
awww img "$WP_PATH" \
    --resize crop \
    --filter Lanczos3 \
    --transition-type fade \
    --transition-duration 1.8 \
    --transition-fps 120 \
    --transition-bezier 0.42,0,0.58,1
printf '%s\n' "$WP_PATH" > "$HOME/.config/wallpapers/.current"

LOCK_CONFIG="$HOME/.config/hypr/hyprlock.conf"
if [ -f "$LOCK_CONFIG" ]; then
    sed -i "s|^    path = .*|    path = $STILL|" "$LOCK_CONFIG"
fi

mkdir -p "$HOME/.cache/matugen"
run_if_exists matugen image -m dark --source-color-index 0 "$STILL"

if [[ "$RELOAD_APPS" == "--generate-only" || "$RELOAD_APPS" == "-g" ]]; then
    echo "Generate only. Skipping app reload."
    exit 0
fi

if command -v makoctl >/dev/null 2>&1; then
    makoctl reload >/dev/null 2>&1 || true
fi

"$HOME/.config/ags/scripts/notify.sh" Wallpaper "Wallpaper" "$NOTIFY_NAME" "$STILL"

for SOCKET in /tmp/kitty-*; do
    if [ -S "$SOCKET" ]; then
        run_if_exists kitty @ --to "unix:$SOCKET" set-colors -a -c ~/.config/kitty/kitty-colors.conf
    fi
done

for sock in /tmp/nvim*; do
    if [ -S "$sock" ]; then
        run_if_exists nvim --server "$sock" --remote-send "<cmd>colorscheme lush-colors<CR>"
    fi
done
