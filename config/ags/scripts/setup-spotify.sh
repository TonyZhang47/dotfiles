#!/usr/bin/env bash
# User-writable Spotify + Spicetify so the rice can recolor the client.
set -euo pipefail

SPOT_SRC="/opt/spotify"
SPOT_DST="$HOME/.local/opt/spotify"
SPICE_DST="$HOME/.local/opt/spicetify"
BIN="$HOME/.local/bin"
VER="2.45.3"
TAR="spicetify-${VER}-linux-amd64.tar.gz"
URL="https://github.com/spicetify/cli/releases/download/v${VER}/${TAR}"

mkdir -p "$SPOT_DST" "$SPICE_DST" "$BIN"

need_copy=0
if [ ! -x "$SPOT_DST/spotify" ] || [ "$SPOT_SRC/spotify" -nt "$SPOT_DST/spotify" ]; then
    need_copy=1
fi
if [ "$need_copy" -eq 1 ]; then
    # Package binary is mode 555, so cp cannot overwrite it in place.
    rm -f "$SPOT_DST/spotify"
    cp -a "$SPOT_SRC/spotify" "$SPOT_DST/spotify"
    rm -rf "$SPOT_DST/Apps"
    cp -a "$SPOT_SRC/Apps" "$SPOT_DST/Apps"
elif [ ! -d "$SPOT_DST/Apps" ]; then
    cp -a "$SPOT_SRC/Apps" "$SPOT_DST/Apps"
fi

for path in "$SPOT_SRC"/*; do
    name=$(basename "$path")
    case "$name" in
        spotify|Apps) continue ;;
    esac
    ln -sfn "$path" "$SPOT_DST/$name"
done

# Launcher stays in front of PATH. If pacman ships a newer client, refresh
# this copy before starting so the binary matches the libraries it links.
cat > "$BIN/spotify" <<EOF
#!/usr/bin/env bash
if [ -x "$SPOT_SRC/spotify" ] && [ "$SPOT_SRC/spotify" -nt "$SPOT_DST/spotify" ]; then
    "$HOME/.config/ags/scripts/setup-spotify.sh"
fi
XDG_CONFIG_HOME=\${XDG_CONFIG_HOME:-\$HOME/.config}
flags=()
if [ -f "\$XDG_CONFIG_HOME/spotify-flags.conf" ]; then
    mapfile -t flags < <(grep -v '^#' "\$XDG_CONFIG_HOME/spotify-flags.conf" | grep -v '^\$')
fi
exec "$SPOT_DST/spotify" "\${flags[@]}" "\$@"
EOF
chmod +x "$BIN/spotify"

if [ ! -x "$SPICE_DST/spicetify" ]; then
    tmp=$(mktemp -d)
    curl -fsSL "$URL" -o "$tmp/$TAR"
    tar -C "$SPICE_DST" -xzf "$tmp/$TAR"
    rm -rf "$tmp"
    chmod +x "$SPICE_DST/spicetify"
fi

ln -sfn "$SPICE_DST/spicetify" "$BIN/spicetify"

export PATH="$BIN:$PATH"
mkdir -p "$HOME/.config/spicetify/Themes/rice"

# First run writes config-xpui.ini
spicetify >/dev/null 2>&1 || true

cfg="$HOME/.config/spicetify/config-xpui.ini"
if [ -f "$cfg" ]; then
    spicetify config spotify_path "$SPOT_DST"
    spicetify config prefs_path "$HOME/.config/spotify/prefs"
    spicetify config current_theme rice
    spicetify config color_scheme Base
    spicetify config inject_css 1 replace_colors 1 overwrite_assets 1
    spicetify config inject_theme_js 0
fi

# A newer client replaced Apps/, so the old backup must not be reused.
if [ "$need_copy" -eq 1 ] && command -v spicetify >/dev/null 2>&1; then
    spicetify clear || true
    spicetify backup apply || true
fi
