#!/usr/bin/env python3
"""Alt+Tab: Windows-style tap — swap the last two windows on this desktop."""
import json
import subprocess


def hypr(*args):
    return subprocess.run(
        ["hyprctl", *args],
        check=False,
        capture_output=True,
        text=True,
    )


def active_workspace_id():
    try:
        ws = json.loads(hypr("-j", "activeworkspace").stdout or "{}")
    except json.JSONDecodeError:
        return None
    return ws.get("id")


def desktop_windows():
    try:
        data = json.loads(hypr("-j", "clients").stdout or "[]")
    except json.JSONDecodeError:
        return []
    current = active_workspace_id()
    out = []
    for c in data:
        cls = (c.get("class") or "").lower()
        if not c.get("mapped") or c.get("hidden"):
            continue
        if cls in ("", "rofi", "gjs"):
            continue
        if not c.get("address"):
            continue
        ws = (c.get("workspace") or {}).get("id")
        if current is not None and ws != current:
            continue
        out.append(c)
    out.sort(key=lambda w: w.get("focusHistoryID", 9999))
    return out


def focus(win):
    addr = win.get("address")
    if not addr:
        return
    hypr("dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})')
    if win.get("floating"):
        hypr("dispatch", "hl.dsp.window.bring_to_top()")


def main():
    wins = desktop_windows()
    if len(wins) < 2:
        return
    focus(wins[1])


if __name__ == "__main__":
    main()
