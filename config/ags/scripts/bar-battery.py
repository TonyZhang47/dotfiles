#!/usr/bin/env python3
"""Battery state for the bar.

Emits one JSON line:
  {"capacity": 52, "icon": "...", "state": "warning", "charging": false,
   "tooltip": "52%  -  2 h 40 min to empty"}

The icon sets and the warning thresholds are the ones the waybar battery module
used, so the bar shows the same glyph at the same charge level.
"""
import json
import glob
import os
import subprocess

DISCHARGING = [chr(c) for c in (
    0xf008e, 0xf007a, 0xf007b, 0xf007c, 0xf007d, 0xf007e,
    0xf007f, 0xf0080, 0xf0081, 0xf0082, 0xf0079)]
CHARGING = [chr(c) for c in (
    0xf089f, 0xf089c, 0xf0086, 0xf0087, 0xf0088, 0xf089d,
    0xf0089, 0xf089e, 0xf008a, 0xf008b, 0xf0085)]
WARNING = 25
CRITICAL = 12


def read(path, default=""):
    try:
        with open(path) as handle:
            return handle.read().strip()
    except OSError:
        return default


def main():
    batteries = sorted(glob.glob("/sys/class/power_supply/BAT*"))
    if not batteries:
        print(json.dumps({"capacity": 0, "icon": "", "state": "",
                          "charging": False, "tooltip": "No battery",
                          "present": False}, ensure_ascii=False))
        return
    base = batteries[0]
    try:
        capacity = int(read(os.path.join(base, "capacity"), "0") or 0)
    except ValueError:
        capacity = 0
    capacity = max(0, min(100, capacity))
    status = read(os.path.join(base, "status"), "Unknown")
    # "Not charging" is AC connected at a high charge; still treat it as plugged in
    # so the bolt glyph shows, the way waybar's charging icons did.
    ac_online = any(
        read(os.path.join(path, "online")) == "1"
        for path in glob.glob("/sys/class/power_supply/A*") + glob.glob("/sys/class/power_supply/ADP*")
    )
    charging = status in ("Charging", "Full", "Not charging") or ac_online

    icons = CHARGING if charging else DISCHARGING
    icon = icons[min(len(icons) - 1, capacity * len(icons) // 100)]

    state = ""
    if not charging:
        if capacity <= CRITICAL:
            state = "critical"
        elif capacity <= WARNING:
            state = "warning"

    remaining = ""
    try:
        remaining = subprocess.run(
            [os.path.expanduser("~/.config/ags/scripts/get-time-left.sh")],
            capture_output=True, text=True, timeout=4).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        remaining = ""
    if remaining.startswith("Battery status:"):
        remaining = status

    print(json.dumps({
        "capacity": capacity,
        "icon": icon,
        "state": state,
        "charging": charging,
        "present": True,
        "tooltip": f"{capacity}%  ·  {remaining}" if remaining else f"{capacity}%",
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
