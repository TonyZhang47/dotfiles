#!/usr/bin/env bash
# Push the current wallpaper palette into every app that can follow it.
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"

# GTK4 user CSS must be a real file. nwg-look left a symlink into the system theme;
# writing through that would overwrite adw-gtk3-dark itself.
for css in "$HOME/.config/gtk-3.0/gtk.css" "$HOME/.config/gtk-4.0/gtk.css"; do
    if [ -L "$css" ]; then
        rm -f "$css"
    fi
done

link_firefox() {
    local profile="$1"
    local chrome="$profile/chrome"
    local theme="$HOME/.config/firefox-theme"
    [ -d "$profile" ] || return 0
    # Firefox often skips a chrome/ directory that is a symlink, and can
    # ignore userChrome.css that is itself a symlink. Copy real files.
    if [ -L "$chrome" ]; then
        rm -f "$chrome"
    fi
    mkdir -p "$chrome"
    for f in userChrome.css userContent.css colors.css; do
        [ -f "$theme/$f" ] || continue
        rm -f "$chrome/$f"
        cp -f "$theme/$f" "$chrome/$f"
    done
    cp -f "$theme/user.js" "$profile/user.js"
}

link_firefox "$HOME/.config/mozilla/firefox/wh2fn9ni.dev-edition-default"
link_firefox "$HOME/.config/mozilla/firefox/j1fhq2y8.default-release"
link_firefox "$HOME/.config/mozilla/firefox/044cb1z1.default"

python3 "$HOME/.config/ags/scripts/apply-app-theme.py" || true

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme true >/dev/null 2>&1 || true
fi

if command -v spicetify >/dev/null 2>&1 && [ -x "$HOME/.local/opt/spotify/spotify" ]; then
    if ! spicetify refresh >/dev/null 2>&1; then
        spicetify apply >/dev/null 2>&1 || true
    fi
fi
