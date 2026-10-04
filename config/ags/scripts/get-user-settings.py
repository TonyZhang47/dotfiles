#!/usr/bin/env python3
"""Read persisted Hyprland user settings for the Super+H popup."""
import json
import os

PATH = os.path.expanduser("~/.config/hypr/user-settings.json")
DEFAULTS = {
    "sensitivity": 0.5,
    "scroll_factor": 0.2,
    "gaps_in": 8,
    "gaps_out": 18,
    "rounding": 14,
    "inactive_opacity": 0.9,
    "animations": True,
    "accel_profile": "flat",
}


def load():
    data = dict(DEFAULTS)
    try:
        with open(PATH, encoding="utf-8") as fh:
            raw = json.load(fh)
        if isinstance(raw, dict):
            data.update(raw)
    except (OSError, json.JSONDecodeError):
        pass
    return data


def view(data):
    sens = float(data.get("sensitivity", 0.5))
    scroll = float(data.get("scroll_factor", 0.2))
    opacity = float(data.get("inactive_opacity", 0.9))
    accel = str(data.get("accel_profile") or "flat")
    anim = bool(data.get("animations", True))
    return {
        "sensitivity": round(sens, 2),
        "sensitivity_i": int(round((sens + 1.0) * 100)),
        "sensitivity_label": f"{sens:+.2f}",
        "scroll_factor": round(scroll, 2),
        "scroll_i": int(round(scroll * 100)),
        "scroll_label": f"{scroll:.2f}",
        "gaps_in": int(data.get("gaps_in", 8)),
        "gaps_out": int(data.get("gaps_out", 18)),
        "rounding": int(data.get("rounding", 14)),
        "inactive_opacity": round(opacity, 2),
        "opacity_i": int(round(opacity * 100)),
        "opacity_label": f"{int(round(opacity * 100))}%",
        "animations": anim,
        "animations_label": "On" if anim else "Off",
        "accel_profile": accel,
        "accel_label": accel.capitalize(),
    }


if __name__ == "__main__":
    print(json.dumps(view(load())), flush=True)
