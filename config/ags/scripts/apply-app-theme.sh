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

# Dark GTK loads gtk-dark.css as well as gtk.css. A symlink to the stock
# theme puts the old colors back on top of the wallpaper palette.
sync_gtk_dark() {
    local css="$1/gtk.css"
    local dark="$1/gtk-dark.css"
    [ -f "$css" ] || return 0
    if [ -L "$dark" ]; then
        rm -f "$dark"
    fi
    cp -f "$css" "$dark"
}
sync_gtk_dark "$HOME/.config/gtk-3.0"
sync_gtk_dark "$HOME/.config/gtk-4.0"

if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-application-prefer-dark-theme true >/dev/null 2>&1 || true
    # Nemo reads the Cinnamon theme name and would stay on stock Adwaita.
    gsettings set org.cinnamon.desktop.interface gtk-theme adw-gtk3-dark >/dev/null 2>&1 || true
    gsettings set org.cinnamon.desktop.interface icon-theme Adwaita >/dev/null 2>&1 || true
    # Programs that watch the theme name reload their CSS when it changes.
    gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark >/dev/null 2>&1 || true
    gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark >/dev/null 2>&1 || true
fi

# The folder dialog is a separate process. It keeps the palette from when
# it started, so restart it after the CSS is in place.
if command -v systemctl >/dev/null 2>&1; then
    systemctl --user restart xdg-desktop-portal-gtk.service >/dev/null 2>&1 || true
fi

# Nemo does not reread gtk.css on its own.
if pgrep -x nemo >/dev/null 2>&1; then
    nemo_args=$(ps -o args= -C nemo | head -n 1)
    pkill -x nemo >/dev/null 2>&1 || true
    for _ in 1 2 3 4 5 6 7 8 9 10; do
        pgrep -x nemo >/dev/null 2>&1 || break
        sleep 0.15
    done
    # shellcheck disable=SC2086
    setsid -f ${nemo_args:-nemo} >/dev/null 2>&1 || true
fi
