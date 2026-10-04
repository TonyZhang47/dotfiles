#!/usr/bin/env bash
# Workspace switching for the dashboard.
#   bar-workspace.sh 3            -> go to Hyprland workspace 3
#   bar-workspace.sh scroll up    -> previous pill (1-9, then 0)
#   bar-workspace.sh scroll down  -> next pill
#
# Hyprland is configured with the Lua API here, where "hyprctl dispatch
# workspace N" is not understood; the dispatcher has to be given Lua.

go() { hyprctl dispatch "hl.dsp.focus({ workspace = $1 })" >/dev/null; }

ORDER_FILE="${XDG_RUNTIME_DIR:-/tmp}/ags-bar-ws-order.json"

scroll() {
    python3 - "$1" "$ORDER_FILE" <<'PY'
import json, subprocess, sys

direction, path = sys.argv[1], sys.argv[2]
order = list(range(1, 11))
active = 1
try:
    data = json.load(open(path, encoding="utf-8"))
    if isinstance(data.get("active"), int):
        active = data["active"]
except (OSError, json.JSONDecodeError):
    pass

try:
    idx = order.index(active)
except ValueError:
    idx = 0

if direction == "up":
    idx = (idx - 1) % len(order)
else:
    idx = (idx + 1) % len(order)

wid = order[idx]
subprocess.run(
    ["hyprctl", "dispatch", f"hl.dsp.focus({{ workspace = {wid} }})"],
    check=False,
    stdout=subprocess.DEVNULL,
    stderr=subprocess.DEVNULL,
)
PY
}

case "$1" in
    scroll)
        case "$2" in
            up) scroll up ;;
            down) scroll down ;;
        esac
        ;;
    [0-9]*) go "$1" ;;
esac
