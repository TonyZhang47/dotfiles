#!/usr/bin/env python3
"""Native messaging host: push the wallpaper palette into Firefox."""
from __future__ import annotations

import json
import os
import struct
import sys
import threading
import time
from pathlib import Path

HOME = Path.home()
COLORS = HOME / ".config/rice/colors.env"


def send(message: dict) -> None:
    data = json.dumps(message).encode("utf-8")
    sys.stdout.buffer.write(struct.pack("<I", len(data)))
    sys.stdout.buffer.write(data)
    sys.stdout.buffer.flush()


def read_colors() -> dict[str, str]:
    env: dict[str, str] = {}
    if not COLORS.is_file():
        return env
    for line in COLORS.read_text(encoding="utf-8").splitlines():
        if "=" in line and not line.startswith("#"):
            key, val = line.split("=", 1)
            env[key.strip()] = val.strip()
    return env


def theme_message() -> dict | None:
    c = read_colors()
    needed = ("RICE_BG", "RICE_BG2", "RICE_BG3", "RICE_MUTED", "RICE_ACCENT", "RICE_FG", "RICE_BORDER")
    if not all(c.get(key) for key in needed):
        return None
    bg, bg2, bg3 = c["RICE_BG"], c["RICE_BG2"], c["RICE_BG3"]
    muted, accent, fg, border = c["RICE_MUTED"], c["RICE_ACCENT"], c["RICE_FG"], c["RICE_BORDER"]
    return {
        "colors": {
            "frame": bg,
            "frame_inactive": bg,
            "toolbar": bg,
            "toolbar_text": fg,
            "icons": accent,
            "icons_attention": fg,
            "toolbar_top_separator": bg,
            "toolbar_bottom_separator": bg,
            "toolbar_vertical_separator": bg2,
            "tab_selected": bg2,
            "tab_text": fg,
            "tab_background_text": muted,
            "tab_line": accent,
            "tab_loading": accent,
            "toolbar_field": bg2,
            "toolbar_field_text": fg,
            "toolbar_field_border": border,
            "toolbar_field_focus": bg2,
            "toolbar_field_text_focus": fg,
            "popup": bg2,
            "popup_text": fg,
            "popup_border": border,
            "popup_highlight": bg3,
            "popup_highlight_text": fg,
            "sidebar": bg,
            "sidebar_text": fg,
            "sidebar_border": bg,
            "sidebar_highlight": bg2,
            "sidebar_highlight_text": fg,
            "button_background_hover": bg3,
            "button_background_active": bg2,
            "ntp_background": bg,
            "ntp_text": fg,
            "bookmark_text": fg,
        }
    }


def pump() -> None:
    """Firefox disconnects the host if stdin is never read."""
    while True:
        header = sys.stdin.buffer.read(4)
        if not header:
            os._exit(0)
        size = struct.unpack("<I", header)[0]
        if size:
            sys.stdin.buffer.read(size)


def main() -> None:
    threading.Thread(target=pump, daemon=True).start()
    last = None
    while True:
        stamp = COLORS.stat().st_mtime if COLORS.is_file() else 0
        if stamp != last:
            message = theme_message()
            if message is not None:
                send(message)
            last = stamp
        time.sleep(0.4)


if __name__ == "__main__":
    main()
