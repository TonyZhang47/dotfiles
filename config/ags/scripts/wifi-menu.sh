#!/usr/bin/env bash
# Rofi Wi-Fi picker. Used by the bar and the control center.
set -u
export PATH="$HOME/.local/bin:$PATH"

ROFI=(rofi -dmenu -i -p "Wi-Fi" -config "$HOME/.config/rofi/config.rasi" -theme-str 'listview { lines: 12; fixed-height: false; }')
SEP=' | '

notify() {
    "$HOME/.config/ags/scripts/notify.sh" Wi-Fi "$1" "${2:-}"
}

wifi_on() { [[ "$(nmcli -t -f WIFI g)" == "enabled" ]]; }

field() { awk -F ' \\| ' -v n="$1" '{print $n}' <<<"$2"; }

connect_ssid() {
    local ssid="$1" security="$2"
    if nmcli -t -f NAME,TYPE connection show | awk -F: -v s="$ssid" '$1==s && $2=="802-11-wireless"{found=1} END{exit !found}'; then
        notify "Wi-Fi" "Connecting to $ssid…"
        nmcli -w 20 connection up "$ssid" && notify "Wi-Fi" "Connected to $ssid"
        return
    fi
    if [[ "$security" == *802.1X* ]]; then
        notify "Wi-Fi" "$ssid needs 802.1X. Opening the editor."
        nm-connection-editor >/dev/null 2>&1 &
        return
    fi
    if [ -z "$security" ]; then
        notify "Wi-Fi" "Connecting to $ssid…"
        nmcli -w 20 device wifi connect "$ssid" && notify "Wi-Fi" "Connected to $ssid"
        return
    fi
    local pass
    pass=$(rofi -dmenu -password -p "Password for $ssid" -config "$HOME/.config/rofi/config-password.rasi") || return 0
    [ -z "$pass" ] && return 0
    notify "Wi-Fi" "Connecting to $ssid…"
    if nmcli -w 20 device wifi connect "$ssid" password "$pass"; then
        notify "Wi-Fi" "Connected to $ssid"
    else
        notify "Wi-Fi" "Could not connect to $ssid"
    fi
}

if ! wifi_on; then
    case "$(printf '%s\n' "Enable Wi-Fi" "Network editor" | "${ROFI[@]}")" in
        "Enable Wi-Fi") nmcli radio wifi on && notify "Wi-Fi" "Enabled" ;;
        "Network editor") nm-connection-editor >/dev/null 2>&1 & ;;
    esac
    exit 0
fi

nmcli device wifi rescan >/dev/null 2>&1 &

ACTIVE=$(nmcli -t -f NAME,TYPE,ACTIVE connection show | awk -F: '$2=="802-11-wireless" && $3=="yes"{print $1; exit}')

LINES=("Disable Wi-Fi" "Refresh" "Network editor")
[ -n "$ACTIVE" ] && LINES+=("Disconnect${SEP}$ACTIVE")
LINES+=("--- Saved ---")
while IFS=: read -r name type active; do
    [ "$type" = "802-11-wireless" ] || continue
    tag=""
    [ "$active" = "yes" ] && tag=" (current)"
    LINES+=("Saved${SEP}${name}${tag}")
done < <(nmcli -t -f NAME,TYPE,ACTIVE connection show)

LINES+=("--- Nearby ---")
declare -A SEEN=()
declare -A SEC=()
while IFS= read -r line; do
    inuse=${line%%:*}
    rest=${line#*:}
    signal=${rest%%:*}
    rest=${rest#*:}
    security=${rest%%:*}
    ssid=${rest#*:}
    [ -n "$ssid" ] || continue
    [ -z "${SEEN[$ssid]+x}" ] || continue
    SEEN[$ssid]=1
    SEC[$ssid]=$security
    tag=""
    [ "$inuse" = "*" ] && tag=" (current)"
    LINES+=("${signal}%${SEP}${ssid}${tag}")
done < <(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list)

CHOSEN=$(printf '%s\n' "${LINES[@]}" | "${ROFI[@]}")
[ -z "$CHOSEN" ] && exit 0

case "$CHOSEN" in
    "Disable Wi-Fi") nmcli radio wifi off && notify "Wi-Fi" "Disabled" ;;
    "Refresh") exec "$0" ;;
    "Network editor") nm-connection-editor >/dev/null 2>&1 & ;;
    Disconnect*)
        nmcli connection down "$ACTIVE"
        ;;
    "---"*) exit 0 ;;
    Saved*)
        name=$(field 2 "$CHOSEN")
        name=${name% (current)}
        notify "Wi-Fi" "Connecting to $name…"
        nmcli -w 20 connection up "$name" && notify "Wi-Fi" "Connected to $name"
        ;;
    *)
        ssid=$(field 2 "$CHOSEN")
        ssid=${ssid% (current)}
        connect_ssid "$ssid" "${SEC[$ssid]:-}"
        ;;
esac
