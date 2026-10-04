#!/usr/bin/env python3
"""Clipboard history. Watch with `watch`, pick with `pick` (Ctrl+Super+V)."""
from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "clip-history"
STORE = CACHE / "history.json"
LIMIT = 80
ROFI = [
    "rofi",
    "-dmenu",
    "-i",
    "-p",
    "Clipboard",
    "-config",
    str(Path.home() / ".config/rofi/config.rasi"),
    "-theme-str",
    "listview { lines: 14; fixed-height: false; }",
]


def load() -> list[str]:
    if not STORE.is_file():
        return []
    try:
        data = json.loads(STORE.read_text())
        if isinstance(data, list):
            return [x for x in data if isinstance(x, str) and x]
    except json.JSONDecodeError:
        return []
    return []


def save(items: list[str]) -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    STORE.write_text(json.dumps(items[:LIMIT], ensure_ascii=False))


def preview(text: str) -> str:
    one = " ".join(text.replace("\t", " ").splitlines()).strip()
    if len(one) > 96:
        one = one[:93] + "…"
    return one or "(empty)"


def add_text(text: str) -> None:
    text = text.replace("\x00", "")
    if not text.strip():
        return
    items = [x for x in load() if x != text]
    items.insert(0, text)
    save(items)


def cmd_add() -> None:
    add_text(sys.stdin.read())


def cmd_watch() -> None:
    CACHE.mkdir(parents=True, exist_ok=True)
    os.execvp(
        "wl-paste",
        ["wl-paste", "--type", "text", "--watch", sys.argv[0], "add"],
    )


def cmd_pick() -> None:
    items = load()
    if not items:
        subprocess.run(
            ROFI + ["-mesg", "Clipboard is empty — copy something first"],
            input="",
            text=True,
            check=False,
        )
        return
    listing = "\n".join(f"{i}\t{preview(t)}" for i, t in enumerate(items))
    picked = subprocess.run(
        ROFI,
        input=listing,
        text=True,
        capture_output=True,
        check=False,
    ).stdout.strip()
    if not picked:
        return
    idx_s = picked.split("\t", 1)[0]
    try:
        idx = int(idx_s)
        text = items[idx]
    except (ValueError, IndexError):
        return
    subprocess.run(["wl-copy", "--", text], check=False)
    add_text(text)


def main() -> None:
    action = sys.argv[1] if len(sys.argv) > 1 else "pick"
    if action == "add":
        cmd_add()
    elif action == "watch":
        cmd_watch()
    elif action == "pick":
        cmd_pick()
    else:
        sys.exit(f"usage: {sys.argv[0]} watch|add|pick")


if __name__ == "__main__":
    main()
