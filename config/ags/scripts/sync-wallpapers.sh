#!/usr/bin/env bash
# Keep wallpaper folders in sync with Super+G / Super+Shift+T and theme caches.
#   static: ~/.config/wallpapers  (jpg/png/webp)  Super+G
#   live:   ~/.config/live-wallpapers (gif/webp) Super+Shift+T
#   --live  sync only the live folder
#   --one FILE  sync a single file
# Bound to a watcher on Hyprland start. Safe to run by hand.

set -euo pipefail
STATIC_DIR="$HOME/.config/wallpapers"
LIVE_DIR="$HOME/.config/live-wallpapers"
STATIC_CACHE="$HOME/.cache/matugen/wallpapers"
LIVE_CACHE="$HOME/.cache/matugen/live-wallpapers"
PICKER_DIR=""
LOCK="${XDG_RUNTIME_DIR:-/tmp}/wallpaper-sync.lock"
CURRENT_FILE="$STATIC_DIR/.current"

KIND="all"
ONE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --live) KIND="live"; shift ;;
        --static) KIND="static"; shift ;;
        --one) ONE="${2:-}"; shift 2 ;;
        *) shift ;;
    esac
done

mkdir -p "$STATIC_DIR" "$LIVE_DIR" "$STATIC_CACHE" "$LIVE_CACHE"

stem_of() {
    local base
    base=$(basename "$1")
    echo "${base%.*}"
}

ext_lower() {
    echo "${1##*.}" | tr 'A-Z' 'a-z'
}

is_static() {
    local base ext
    base=$(basename "$1")
    case "$base" in
        preview-*|.current|.*) return 1 ;;
    esac
    ext=$(ext_lower "$base")
    case "$ext" in
        jpg|jpeg|png|webp) return 0 ;;
        *) return 1 ;;
    esac
}

is_live() {
    local base ext
    base=$(basename "$1")
    case "$base" in
        preview-*|.current|README|README.txt|.*) return 1 ;;
    esac
    ext=$(ext_lower "$base")
    case "$ext" in
        gif|webp) return 0 ;;
        *) return 1 ;;
    esac
}

source_static() {
    local stem="$1" ext
    for ext in jpg jpeg png webp JPG JPEG PNG WEBP; do
        if [ -f "$STATIC_DIR/$stem.$ext" ]; then
            printf '%s\n' "$STATIC_DIR/$stem.$ext"
            return 0
        fi
    done
    return 1
}

source_live() {
    local stem="$1" ext
    for ext in gif GIF webp WEBP; do
        if [ -f "$LIVE_DIR/$stem.$ext" ]; then
            printf '%s\n' "$LIVE_DIR/$stem.$ext"
            return 0
        fi
    done
    return 1
}

theme_source() {
    local src="$1" ext still
    ext=$(ext_lower "$src")
    if [ "$ext" != gif ]; then
        printf '%s\n' "$src"
        return 0
    fi
    still="$LIVE_DIR/preview-$(stem_of "$src").jpg"
    if [ -f "$still" ]; then
        printf '%s\n' "$still"
        return 0
    fi
    printf '%s\n' "$src"
}

make_preview() {
    local src="$1" dest="$2"
    [ -f "$dest" ] && return 0
    command -v magick >/dev/null || return 0
    local ext
    ext=$(ext_lower "$src")
    if [ "$ext" = gif ]; then
        magick "${src}[0]" -resize '600x400^' -gravity center -extent 600x400 -quality 85 "$dest"
    else
        magick "$src" -resize '600x400^' -gravity center -extent 600x400 -quality 85 "$dest"
    fi
}

make_theme() {
    local src="$1" dest="$2" tmp theme_src
    [ -s "$dest" ] && return 0
    command -v matugen >/dev/null || return 0
    theme_src=$(theme_source "$src")
    tmp=$(mktemp)
    if matugen image -m dark --source-color-index 0 --dry-run -q -j hex "$theme_src" >"$tmp" 2>/dev/null \
        && python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$tmp"; then
        mv "$tmp" "$dest"
    else
        rm -f "$tmp"
    fi
}

list_static_stems() {
    shopt -s nullglob
    local f
    for f in "$STATIC_DIR"/*; do
        [ -f "$f" ] || continue
        is_static "$f" || continue
        stem_of "$f"
    done | sort -Vu
}

refresh_picker() {
    return 0
}

switch_if_current_missing() {
    local current=""
    if [ -f "$CURRENT_FILE" ]; then
        current=$(head -n 1 "$CURRENT_FILE")
    fi
    if [ -n "$current" ] && [ -f "$current" ]; then
        return 0
    fi
    local first
    first=$(list_static_stems | head -n 1)
    [ -n "$first" ] || return 0
    "$HOME/.config/ags/scripts/update-color.sh" "$first" >/dev/null 2>&1 || true
}

sync_static_one() {
    local src="$1" stem
    is_static "$src" || return 0
    [ -f "$src" ] || return 0
    stem=$(stem_of "$src")
    make_preview "$src" "$STATIC_DIR/preview-${stem}.jpg"
    make_theme "$src" "$STATIC_CACHE/${stem}.json"
}

sync_live_one() {
    local src="$1" stem
    is_live "$src" || return 0
    [ -f "$src" ] || return 0
    stem=$(stem_of "$src")
    make_preview "$src" "$LIVE_DIR/preview-${stem}.jpg"
    make_theme "$src" "$LIVE_CACHE/${stem}.json"
}

cleanup_static() {
    shopt -s nullglob
    local f stem
    for f in "$STATIC_DIR"/preview-*.jpg; do
        stem=$(basename "$f")
        stem=${stem#preview-}
        stem=${stem%.jpg}
        if ! source_static "$stem" >/dev/null; then
            rm -f "$f"
        fi
    done
    for f in "$STATIC_CACHE"/*.json; do
        [ -e "$f" ] || continue
        stem=$(basename "$f" .json)
        if ! source_static "$stem" >/dev/null; then
            rm -f "$f"
        fi
    done
}

cleanup_live() {
    shopt -s nullglob
    local f stem
    for f in "$LIVE_DIR"/preview-*.jpg; do
        stem=$(basename "$f")
        stem=${stem#preview-}
        stem=${stem%.jpg}
        if ! source_live "$stem" >/dev/null; then
            rm -f "$f"
        fi
    done
    for f in "$LIVE_CACHE"/*.json; do
        [ -e "$f" ] || continue
        stem=$(basename "$f" .json)
        if ! source_live "$stem" >/dev/null; then
            rm -f "$f"
        fi
    done
}

sync_static_all() {
    shopt -s nullglob
    local f
    for f in "$STATIC_DIR"/*; do
        [ -f "$f" ] || continue
        sync_static_one "$f"
    done
    cleanup_static
}

sync_live_all() {
    shopt -s nullglob
    local f
    for f in "$LIVE_DIR"/*; do
        [ -f "$f" ] || continue
        sync_live_one "$f"
    done
    cleanup_live
}

exec 9>"$LOCK"
flock 9

if [ -n "$ONE" ]; then
    case "$ONE" in
        "$LIVE_DIR"/*) sync_live_one "$ONE"; cleanup_live ;;
        *) sync_static_one "$ONE"; cleanup_static ;;
    esac
    switch_if_current_missing
    refresh_picker
    exit 0
fi

if [ "$KIND" = "static" ] || [ "$KIND" = "all" ]; then
    sync_static_all
fi
if [ "$KIND" = "live" ] || [ "$KIND" = "all" ]; then
    sync_live_all
fi
switch_if_current_missing
refresh_picker
