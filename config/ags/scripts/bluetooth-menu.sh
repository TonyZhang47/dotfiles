#!/usr/bin/env bash
# Rofi Bluetooth picker. Used by the control center.
set -u
export PATH="$HOME/.local/bin:$PATH"

ROFI=(rofi -dmenu -i -p "Bluetooth" -config "$HOME/.config/rofi/config.rasi" -theme-str 'listview { lines: 12; fixed-height: false; }')
SEP=' | '

notify() {
    "$HOME/.config/ags/scripts/notify.sh" Bluetooth "$1" "${2:-}"
}

powered() { bluetoothctl show 2>/dev/null | awk '/Powered:/ {print $2; exit}'; }

if [ "$(powered)" != "yes" ]; then
    case "$(printf '%s\n' "Enable Bluetooth" | "${ROFI[@]}")" in
        "Enable Bluetooth")
            rfkill unblock bluetooth 2>/dev/null || true
            bluetoothctl power on >/dev/null
            bluetoothctl pairable on >/dev/null
            notify "Bluetooth" "Enabled"
            exec "$0"
            ;;
    esac
    exit 0
fi

LINES=("Disable Bluetooth" "Scan for devices" "--- Devices ---")

declare -A NAMES=()
while read -r _ mac name; do
    [ -n "$mac" ] || continue
    NAMES[$mac]=${name:-$mac}
done < <(bluetoothctl devices 2>/dev/null)

connected() { bluetoothctl devices Connected 2>/dev/null | grep -Fq "$1"; }
paired()    { bluetoothctl devices Paired 2>/dev/null | grep -Fq "$1"; }

if [ ${#NAMES[@]} -eq 0 ]; then
    LINES+=("(none yet — scan)")
else
    for mac in "${!NAMES[@]}"; do
        tag=""
        connected "$mac" && tag=" (connected)"
        paired "$mac" && [ -z "$tag" ] && tag=" (paired)"
        LINES+=("${NAMES[$mac]}${tag}${SEP}${mac}")
    done
fi

CHOSEN=$(printf '%s\n' "${LINES[@]}" | "${ROFI[@]}")
[ -z "$CHOSEN" ] && exit 0

case "$CHOSEN" in
    "Disable Bluetooth")
        bluetoothctl power off >/dev/null
        notify "Bluetooth" "Disabled"
        ;;
    "Scan for devices")
        notify "Bluetooth" "Scanning…"
        bluetoothctl pairable on >/dev/null
        bluetoothctl --timeout 10 scan on >/dev/null
        notify "Bluetooth" "Scan finished"
        exec "$0"
        ;;
    "---"*|"(none"*) exit 0 ;;
    *)
        mac=${CHOSEN##* | }
        name=${NAMES[$mac]:-$mac}
        if connected "$mac"; then
            bluetoothctl disconnect "$mac" >/dev/null
            notify "Bluetooth" "Disconnected $name"
        else
            notify "Bluetooth" "Connecting to $name…"
            bluetoothctl pair "$mac" >/dev/null
            bluetoothctl trust "$mac" >/dev/null
            if bluetoothctl connect "$mac" >/dev/null; then
                notify "Bluetooth" "Connected to $name"
            else
                notify "Bluetooth" "Could not connect to $name"
            fi
        fi
        ;;
esac
