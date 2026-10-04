#!/usr/bin/env python3
"""Media state for the bar, from the active MPRIS player.

Emits JSON lines so one playerctl poll feeds every part of the bar's media
widget:

  {"playing": true, "active": true, "anim": "▃▅▇", "title": "...",
   "artist": "...", "label": "...", "status": "Playing", "tooltip": "..."}

anim  - equalizer frame, only advances while audio is playing
label - title scrolled to a fixed width so it fits the narrow bar
"""
import json
import subprocess
import sys
import time

PLAYERS = "spotify,ncspot,mpv,firefox,%any"
FRAMES = ("▁▃▅", "▃▅▇", "▅▇▅", "▇▅▃", "▅▃▁", "▃▁▃")
PAUSED_ICON = ""
SEPARATOR = "   •   "
WIDTH = 16
INTERVAL = 0.15
# The title scrolls slower than the equalizer animates.
SCROLL_EVERY = 3


def poll():
    """Return (status, title, artist). Status is empty when nothing is loaded."""
    try:
        out = subprocess.run(
            ["playerctl", "--player", PLAYERS, "metadata", "--format",
             "{{status}}\t{{title}}\t{{artist}}"],
            capture_output=True, text=True, timeout=2,
        ).stdout.strip("\n")
    except (OSError, subprocess.SubprocessError):
        return "", "", ""
    if not out:
        return "", "", ""
    parts = out.split("\t")
    while len(parts) < 3:
        parts.append("")
    return parts[0].strip(), parts[1].strip(), parts[2].strip()


def tooltip(status, title, artist):
    lines = [part for part in (title, artist, status) if part]
    return "\n".join(lines)


def main():
    frame = 0
    tick = 0
    offset = 0
    previous = None
    while True:
        status, title, artist = poll()
        playing = status == "Playing"
        active = bool(status)

        if playing:
            anim = FRAMES[frame % len(FRAMES)]
            frame += 1
        elif status == "Paused":
            anim = PAUSED_ICON
            frame = 0
        else:
            anim = ""
            frame = 0

        full = f"{title} — {artist}" if title and artist else title
        if full != previous:
            previous = full
            offset = 0

        if not full:
            label = ""
        elif len(full) <= WIDTH:
            label = full
        else:
            marquee = full + SEPARATOR
            label = (marquee + marquee)[offset:offset + WIDTH]
            # Scroll only while playing, so a paused track stays readable.
            if playing and tick % SCROLL_EVERY == 0:
                offset = (offset + 1) % len(marquee)

        print(json.dumps({
            "playing": playing,
            "active": active,
            "anim": anim,
            "title": title,
            "artist": artist,
            "label": label,
            "status": status,
            "tooltip": tooltip(status, title, artist),
        }, ensure_ascii=False), flush=True)

        tick += 1
        time.sleep(INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, BrokenPipeError):
        sys.exit(0)
