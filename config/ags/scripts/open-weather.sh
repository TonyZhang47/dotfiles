#!/usr/bin/env bash
# Open the Baltimore forecast. gnome-weather if installed, otherwise NWS.
export PATH="$HOME/.local/bin:$PATH"
NWS='https://forecast.weather.gov/MapClick.php?lat=39.2904&lon=-76.6122'

if command -v gnome-weather >/dev/null 2>&1; then
    setsid -f gnome-weather >/dev/null 2>&1
    exit 0
fi

exec "$HOME/.config/ags/scripts/open.sh" firefox-developer-edition "$NWS"
