#!/usr/bin/env python3
"""Super+Tab: Windows Task View — pick any window on any desktop."""
import json
import subprocess
import sys


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


def workspace_label(ws):
    if ws is None:
        return "?"
    if isinstance(ws, int) and ws < 0:
        return "Scratchpad"
    if ws == 10:
        return "0"
    return str(ws)


def all_windows():
    try:
        data = json.loads(hypr("-j", "clients").stdout or "[]")
    except json.JSONDecodeError:
        return []
    out = []
    for c in data:
        cls = (c.get("class") or "").lower()
        if not c.get("mapped") or c.get("hidden"):
            continue
        if cls in ("", "rofi", "gjs"):
            continue
        if not c.get("address"):
            continue
        out.append(c)
    current = active_workspace_id()

    def sort_key(w):
        ws = (w.get("workspace") or {}).get("id")
        here = 0 if ws == current else 1
        ws_ord = 99 if ws is None else ws
        return (here, ws_ord, w.get("focusHistoryID", 9999))

    out.sort(key=sort_key)
    return out


def focus(win):
    addr = win.get("address")
    if not addr:
        return
    hypr("dispatch", f'hl.dsp.focus({{ window = "address:{addr}" }})')
    if win.get("floating"):
        hypr("dispatch", "hl.dsp.window.bring_to_top()")


def main():
    wins = all_windows()
    if not wins:
        return

    lines = []
    by_label = {}
    for w in wins:
        title = (w.get("title") or "").replace("\n", " ").strip() or "Untitled"
        cls = w.get("class") or "app"
        desk = workspace_label((w.get("workspace") or {}).get("id"))
        label = f"Desktop {desk}    {title}    {cls}"
        # Avoid colliding labels if two windows share a title.
        while label in by_label:
            label = label + " "
        lines.append(label)
        by_label[label] = w

    proc = subprocess.run(
        [
            "rofi",
            "-dmenu",
            "-i",
            "-p",
            "Task View",
            "-config",
            "/home/ping/.config/rofi/config.rasi",
            "-theme-str",
            "window { width: 640px; } listview { lines: 12; fixed-height: false; }",
        ],
        input="\n".join(lines) + "\n",
        capture_output=True,
        text=True,
    )
    if proc.returncode != 0:
        return
    choice = (proc.stdout or "").rstrip("\n")
    w = by_label.get(choice)
    if not w:
        return
    focus(w)


if __name__ == "__main__":
    sys.exit(main() or 0)
