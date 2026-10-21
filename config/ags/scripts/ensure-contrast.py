#!/usr/bin/env python3
"""Lift a matugen scheme so wallpaper colors stay on-hue and text stays readable.

Matugen's base16 ramp from a muted image collapses: accent slots land on the
background, and the terminal's bright yellow (fish quotes, commit messages)
disappears. This keeps each wallpaper hue, then raises lightness until the
pairs below pass. Dark surfaces stay dark so light text on buttons still works.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

# Hue used when an accent is too gray to tell red from yellow.
ROLE_HUE = {
    "base08": 6,
    "base09": 28,
    "base0a": 46,
    "base0b": 148,
    "base0c": 188,
    "base0d": 214,
    "base0e": 318,
    "base0f": 350,
}


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.strip().lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def rgb_to_hex(r: int, g: int, b: int) -> str:
    return f"#{r:02x}{g:02x}{b:02x}"


def channel(c: float) -> float:
    c = c / 255
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def rel_lum(value: str) -> float:
    r, g, b = hex_to_rgb(value)
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(a: str, b: str) -> float:
    hi, lo = sorted((rel_lum(a), rel_lum(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def rgb_to_hsl(r: int, g: int, b: int) -> tuple[float, float, float]:
    rf, gf, bf = r / 255, g / 255, b / 255
    mx, mn = max(rf, gf, bf), min(rf, gf, bf)
    l = (mx + mn) / 2
    if mx == mn:
        return 0.0, 0.0, l
    d = mx - mn
    s = d / (2 - mx - mn) if l > 0.5 else d / (mx + mn)
    if mx == rf:
        h = ((gf - bf) / d) % 6
    elif mx == gf:
        h = (bf - rf) / d + 2
    else:
        h = (rf - gf) / d + 4
    return h * 60, s, l


def hsl_to_hex(h: float, s: float, l: float) -> str:
    h = (h % 360) / 360
    s = min(1.0, max(0.0, s))
    l = min(1.0, max(0.0, l))

    def hue(p: float, q: float, t: float) -> float:
        t %= 1
        if t < 1 / 6:
            return p + (q - p) * 6 * t
        if t < 1 / 2:
            return q
        if t < 2 / 3:
            return p + (q - p) * (2 / 3 - t) * 6
        return p

    if s == 0:
        r = g = b = l
    else:
        q = l * (1 + s) if l < 0.5 else l + s - l * s
        p = 2 * l - q
        r = hue(p, q, h + 1 / 3)
        g = hue(p, q, h)
        b = hue(p, q, h - 1 / 3)
    return rgb_to_hex(round(r * 255), round(g * 255), round(b * 255))


def hsl_of(value: str) -> tuple[float, float, float]:
    return rgb_to_hsl(*hex_to_rgb(value))


def lightest(h: float, s: float, against: str, ratio: float, start: float = 0.2) -> str:
    """Lowest lightness at or above start that clears ratio against a darker color."""
    chosen = hsl_to_hex(h, s, 0.92)
    lo, hi = start, 0.94
    for _ in range(24):
        mid = (lo + hi) / 2
        trial = hsl_to_hex(h, s, mid)
        if contrast(trial, against) >= ratio:
            chosen = trial
            hi = mid
        else:
            lo = mid
    return chosen


def darkest_surface(h: float, s: float, bg: str, ratio: float) -> str:
    """Lighten a surface just enough to separate it from the background."""
    chosen = bg
    lo, hi = hsl_of(bg)[2] + 0.01, 0.55
    for _ in range(24):
        mid = (lo + hi) / 2
        trial = hsl_to_hex(h, s, mid)
        if contrast(trial, bg) >= ratio:
            chosen = trial
            hi = mid
        else:
            lo = mid
    return chosen


def slot(data: dict, name: str) -> str:
    return data["base16"][name]["default"]["color"]


def put(data: dict, name: str, value: str) -> None:
    for mode in ("default", "dark"):
        data["base16"][name][mode]["color"] = value


def accent(original: str, hue: float, bg: str, ink: str) -> str:
    h, s, _l = hsl_of(original)
    if s < 0.18:
        h, s = hue, 0.48
    else:
        s = min(0.72, max(s, 0.34))
    # Light enough to read on the dark background, and dark enough that the
    # background color (prompt text, GTK button labels) reads on top of it.
    # 7:1 against the flat background leaves the quote readable through kitty's
    # translucent window, where the wallpaper lightens the real background.
    color = lightest(h, s, bg, 7.0, start=0.55)
    guard = 0
    while contrast(ink, color) < 4.8 and guard < 16:
        h, s, l = hsl_of(color)
        color = hsl_to_hex(h, s, min(0.9, l + 0.025))
        guard += 1
    return color


def lift(data: dict) -> None:
    bg = slot(data, "base00")
    bh, bs, _bl = hsl_of(bg)
    # Keep the wallpaper tint on the gray ramp, but don't let it go neon.
    ramp_s = min(bs if bs > 0.04 else 0.06, 0.22)
    text_h, text_s, _ = hsl_of(slot(data, "base07"))
    if text_s < 0.06:
        text_h, text_s = bh, ramp_s
    text_s = min(text_s, 0.28)

    put(data, "base00", bg)
    put(data, "base01", darkest_surface(bh, ramp_s, bg, 1.28))
    put(data, "base02", darkest_surface(bh, ramp_s, bg, 1.55))
    put(data, "base03", darkest_surface(bh, ramp_s, bg, 1.9))

    base04 = lightest(text_h, text_s, bg, 5.2)
    base05 = lightest(text_h, text_s, bg, 6.6)
    base06 = lightest(text_h, text_s, bg, 7.2)
    base07 = lightest(text_h, max(0.04, text_s * 0.7), bg, 8.0)
    put(data, "base04", base04)
    put(data, "base05", base05)
    put(data, "base06", base06)
    put(data, "base07", base07)

    # Muted text also sits on the raised surface, not only on the background.
    color = slot(data, "base04")
    h, s, l = hsl_of(color)
    guard = 0
    while contrast(color, slot(data, "base01")) < 4.6 and guard < 16:
        l = min(0.9, l + 0.015)
        color = hsl_to_hex(h, s, l)
        guard += 1
    put(data, "base04", color)
    for prev, nxt in (("base04", "base05"), ("base05", "base06"), ("base06", "base07")):
        if rel_lum(slot(data, nxt)) >= rel_lum(slot(data, prev)) + 0.03:
            continue
        h, s, l = hsl_of(slot(data, nxt))
        put(data, nxt, hsl_to_hex(h, s, min(0.92, hsl_of(slot(data, prev))[2] + 0.045)))

    # Selection, badges, and GTK selected rows use base03 under base07 text.
    fg = slot(data, "base07")
    surface = slot(data, "base03")
    h, s, l = hsl_of(surface)
    guard = 0
    while contrast(fg, surface) < 4.5 and guard < 20:
        l = max(hsl_of(bg)[2], l - 0.02)
        surface = hsl_to_hex(h, s, l)
        guard += 1
    put(data, "base03", surface)

    ink = slot(data, "base00")
    for name, hue in ROLE_HUE.items():
        put(data, name, accent(slot(data, name), hue, bg, ink))

    # Spread the prompt pill colors (yellow, blue, magenta) so the chevrons
    # between them stay visible, without dropping black text below 4.8:1.
    spreads = {"base0a": 0.0, "base0d": 0.06, "base0e": 0.11, "base0b": 0.03}
    for name, extra in spreads.items():
        h, s, l = hsl_of(slot(data, name))
        nudged = hsl_to_hex(h, s, min(0.9, l + extra))
        if contrast(ink, nudged) >= 4.8 and contrast(nudged, bg) >= 7.0:
            put(data, name, nudged)

    # Don't let two roles collapse to one hex (a global replace can't tell
    # them apart, and a quote color equal to the background is how this broke).
    used = {bg}
    for name in [
        "base01", "base02", "base03", "base04", "base05", "base06", "base07",
        "base08", "base09", "base0a", "base0b", "base0c", "base0d", "base0e", "base0f",
    ]:
        color = slot(data, name)
        guard = 0
        while color in used and guard < 12:
            h, s, l = hsl_of(color)
            color = hsl_to_hex(h, s, min(0.94, l + 0.015))
            guard += 1
        put(data, name, color)
        used.add(color)


def check(data: dict) -> list[str]:
    bg = slot(data, "base00")
    ink = bg
    problems = []
    need = {
        "base04": 5.0,
        "base05": 6.4,
        "base06": 7.0,
        "base07": 7.5,
    }
    for name, ratio in need.items():
        got = contrast(slot(data, name), bg)
        if got < ratio:
            problems.append(f"{name} on background is {got:.2f}:1, need {ratio}")
    fg = slot(data, "base07")
    for name in ("base01", "base02", "base03"):
        got = contrast(fg, slot(data, name))
        if got < 4.5:
            problems.append(f"text on {name} is {got:.2f}:1, need 4.5")
    for name in ROLE_HUE:
        color = slot(data, name)
        on_bg = contrast(color, bg)
        ink_on = contrast(ink, color)
        if on_bg < 6.5:
            problems.append(f"{name} on background is {on_bg:.2f}:1, need 6.5")
        if ink_on < 4.5:
            problems.append(f"dark text on {name} is {ink_on:.2f}:1, need 4.5")
    if contrast(slot(data, "base04"), slot(data, "base01")) < 4.5:
        problems.append("muted text on base01 is below 4.5:1")
    return problems


def main() -> None:
    path = Path(sys.argv[1])
    data = json.loads(path.read_text(encoding="utf-8"))
    lift(data)
    problems = check(data)
    path.write_text(json.dumps(data), encoding="utf-8")
    if problems:
        print("\n".join(problems), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
