#!/usr/bin/env python3
"""Workspace state for the dashboard, pushed on every relevant Hyprland event.

Always emits Super+1..9 and Super+0 (Hyprland workspace 10), so the pills
match the keys instead of only listing occupied workspaces.
"""
import glob
import json
import os
import socket
import subprocess
import sys

WATCH = (
    b"workspace>>",
    b"createworkspace>>",
    b"destroyworkspace>>",
    b"focusedmon>>",
    b"moveworkspace>>",
    b"openwindow>>",
    b"closewindow>>",
    b"movewindow>>",
)

ORDER_FILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "ags-bar-ws-order.json")

# Super+1..9 -> workspaces 1..9, Super+0 -> workspace 10
IDS = list(range(1, 11))
LABELS = {i: str(i) for i in range(1, 10)}
LABELS[10] = "0"


def hyprctl(*args):
    try:
        out = subprocess.run(["hyprctl", "-j", *args],
                             capture_output=True, text=True, timeout=2).stdout
        return json.loads(out) if out.strip() else None
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        return None


def emit():
    occupied = {}
    for w in hyprctl("workspaces") or []:
        wid = w.get("id")
        if isinstance(wid, int) and wid > 0:
            occupied[wid] = int(w.get("windows") or 0) > 0

    active = (hyprctl("activeworkspace") or {}).get("id", 1)
    listing = [{
        "id": wid,
        "label": LABELS[wid],
        "occupied": bool(occupied.get(wid)),
    } for wid in IDS]
    payload = {"active": active, "list": listing, "order": IDS}
    try:
        with open(ORDER_FILE, "w", encoding="utf-8") as fh:
            json.dump({"active": active, "order": IDS}, fh)
    except OSError:
        pass
    print(json.dumps({"active": active, "list": listing}), flush=True)


def event_socket():
    runtime = os.environ.get("XDG_RUNTIME_DIR", "/run/user/%d" % os.getuid())
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    candidates = [f"{runtime}/hypr/{sig}/.socket2.sock"] if sig else []
    candidates += sorted(glob.glob(f"{runtime}/hypr/*/.socket2.sock"))
    for path in candidates:
        if os.path.exists(path):
            sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            try:
                sock.connect(path)
                return sock
            except OSError:
                sock.close()
    return None


def main():
    emit()
    sock = event_socket()
    if sock is None:
        return
    buf = b""
    while True:
        chunk = sock.recv(4096)
        if not chunk:
            return
        buf += chunk
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            if line.startswith(WATCH):
                emit()


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
