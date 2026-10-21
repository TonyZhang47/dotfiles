#!/usr/bin/env python3
"""Merge wallpaper colors into apps that store theme data as JSON/TOML/conf."""
from __future__ import annotations

import json
import re
from pathlib import Path

HOME = Path.home()
RICE = HOME / ".config/rice"


def load_json(path: Path, default):
    if not path.is_file():
        return default
    text = path.read_text(encoding="utf-8").lstrip("\ufeff")
    if not text.strip():
        return default
    return json.loads(text)


def dump_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")


def hex_to_rgb(value: str) -> tuple[int, int, int]:
    value = value.strip().lstrip("#")
    return int(value[0:2], 16), int(value[2:4], 16), int(value[4:6], 16)


def rgba(value: str, alpha: float) -> str:
    r, g, b = hex_to_rgb(value)
    return f"rgba({r}, {g}, {b}, {alpha})"


def colors() -> dict[str, str]:
    env = {}
    path = RICE / "colors.env"
    if path.is_file():
        for line in path.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.startswith("#"):
                key, val = line.split("=", 1)
                env[key.strip()] = val.strip()
    return env


def merge_vscode() -> None:
    overlay = load_json(RICE / "vscode-colors.json", {})
    if not overlay:
        return
    for rel in (
        "Cursor/User/settings.json",
        "Code - OSS/User/settings.json",
        "Code/User/settings.json",
    ):
        path = HOME / ".config" / rel
        if not path.parent.is_dir():
            continue
        data = load_json(path, {})
        if not isinstance(data, dict):
            continue
        data["workbench.colorCustomizations"] = overlay
        data["window.autoDetectColorScheme"] = False
        data["workbench.preferredDarkColorTheme"] = "Default Dark Modern"
        # The integrated terminal otherwise remaps dim ANSI colors on its own.
        data["terminal.integrated.minimumContrastRatio"] = 4.5
        dump_json(path, data)


def merge_fastfetch() -> None:
    color = load_json(RICE / "fastfetch-color.json", {})
    path = HOME / ".config/fastfetch/config.jsonc"
    if not color or not path.is_file():
        return
    raw = path.read_text(encoding="utf-8")
    # Strip // comments so json.loads can read the jsonc we own.
    stripped = re.sub(r"^\s*//.*$", "", raw, flags=re.M)
    data = json.loads(stripped)
    display = data.setdefault("display", {})
    display["color"] = color
    dump_json(path, data)


def merge_heroic() -> None:
    path = HOME / ".config/heroic/config.json"
    if not path.is_file():
        return
    data = load_json(path, {})
    if not isinstance(data, dict):
        return
    settings = data.setdefault("defaultSettings", {})
    if isinstance(settings, dict):
        settings["theme"] = "rice"
        settings["defaultCustomTheme"] = "rice"
    dump_json(path, data)


def merge_bottom() -> None:
    src = RICE / "bottom-colors.toml"
    dest = HOME / ".config/bottom/bottom.toml"
    if not src.is_file() or not dest.is_file():
        return
    body = dest.read_text(encoding="utf-8")
    colors = src.read_text(encoding="utf-8").strip() + "\n"
    block = "# BEGIN RICE COLORS\n" + colors + "# END RICE COLORS\n"
    if "# BEGIN RICE COLORS" in body:
        body = re.sub(
            r"# BEGIN RICE COLORS\n.*?# END RICE COLORS\n",
            block,
            body,
            flags=re.S,
        )
    else:
        # Drop a leftover uncommented [colors] if we added one earlier.
        body = re.sub(r"\n\[colors\]\n(?:[^\[]*\n)*", "\n", body)
        body = body.rstrip() + "\n\n" + block
    dest.write_text(body, encoding="utf-8")


def patch_hyprlock() -> None:
    c = colors()
    dest = HOME / ".config/hypr/hyprlock.conf"
    if not c or not dest.is_file():
        return
    fg, bg, accent, err = c.get("RICE_FG"), c.get("RICE_BG"), c.get("RICE_ACCENT"), c.get("RICE_ERR")
    if not all((fg, bg, accent, err)):
        return
    text = dest.read_text(encoding="utf-8")
    label_alphas = [0.94, 0.72, 0.82]
    idx = 0

    def next_label(match: re.Match[str]) -> str:
        nonlocal idx
        alpha = label_alphas[min(idx, len(label_alphas) - 1)]
        idx += 1
        return f"color = {rgba(fg, alpha)}"

    text = re.sub(r"^    color = rgba\([^)]+\)$", next_label, text, flags=re.M)
    replacements = {
        r"^    outer_color = rgba\([^)]+\)$": f"    outer_color = {rgba(fg, 0.28)}",
        r"^    inner_color = rgba\([^)]+\)$": f"    inner_color = {rgba(bg, 0.42)}",
        r"^    font_color = rgba\([^)]+\)$": f"    font_color = {rgba(fg, 1.0)}",
        r"^    check_color = rgba\([^)]+\)$": f"    check_color = {rgba(accent, 0.85)}",
        r"^    fail_color = rgba\([^)]+\)$": f"    fail_color = {rgba(err, 0.9)}",
    }
    for pat, val in replacements.items():
        text = re.sub(pat, val, text, flags=re.M)
    text = re.sub(
        r'placeholder_text = <span foreground="##[0-9A-Fa-f]+">',
        f'placeholder_text = <span foreground="##{fg.lstrip("#")}">',
        text,
    )
    dest.write_text(text, encoding="utf-8")


def ensure_mpv_include() -> None:
    path = HOME / ".config/mpv/mpv.conf"
    path.parent.mkdir(parents=True, exist_ok=True)
    line = 'include="~~/colors.conf"\n'
    if not path.is_file():
        path.write_text(line, encoding="utf-8")
        return
    text = path.read_text(encoding="utf-8")
    if "colors.conf" not in text:
        path.write_text(line + text, encoding="utf-8")


def ensure_btop_theme() -> None:
    path = HOME / ".config/btop/btop.conf"
    if not path.is_file():
        return
    text = path.read_text(encoding="utf-8")
    if re.search(r"^color_theme\s*=", text, flags=re.M):
        text = re.sub(r"^color_theme\s*=.*$", 'color_theme = "rice"', text, flags=re.M)
    else:
        text = 'color_theme = "rice"\n' + text
    path.write_text(text, encoding="utf-8")


def rgb_list(value: str) -> list[int]:
    return list(hex_to_rgb(value))


def firefox_theme_colors(bg: str, bg2: str, bg3: str, muted: str, accent: str, fg: str, border: str) -> dict[str, str]:
    return {
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


FIREFOX_BACKGROUND = """\
function apply(message) {
  if (message && message.colors) {
    browser.theme.update({ colors: message.colors });
  }
}

async function baked() {
  try {
    const response = await fetch(browser.runtime.getURL("colors.json"));
    apply({ colors: await response.json() });
  } catch (e) {}
}

function connect() {
  let port;
  try {
    port = browser.runtime.connectNative("rice_theme");
  } catch (e) {
    return;
  }
  port.onMessage.addListener(apply);
  port.onDisconnect.addListener(() => setTimeout(connect, 1000));
}

baked();
connect();
"""


def install_firefox_host() -> None:
    host = HOME / ".config/ags/scripts/firefox-theme-host.py"
    host.chmod(host.stat().st_mode | 0o111)
    manifest = {
        "name": "rice_theme",
        "description": "Apply the wallpaper palette to Firefox",
        "path": str(host),
        "type": "stdio",
        "allowed_extensions": ["rice-theme@local"],
    }
    for directory in (
        HOME / ".mozilla/native-messaging-hosts",
        HOME / ".config/mozilla/native-messaging-hosts",
    ):
        directory.mkdir(parents=True, exist_ok=True)
        (directory / "rice_theme.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


def install_firefox_theme() -> None:
    """Build a native Firefox color theme and point the Dev Edition profile at it."""
    c = colors()
    bg, bg2, bg3 = c.get("RICE_BG"), c.get("RICE_BG2"), c.get("RICE_BG3")
    muted, accent, fg, border = (
        c.get("RICE_MUTED"),
        c.get("RICE_ACCENT"),
        c.get("RICE_FG"),
        c.get("RICE_BORDER"),
    )
    if not all((bg, bg2, bg3, muted, accent, fg, border)):
        return

    theme_dir = HOME / ".config/firefox-theme"
    theme_dir.mkdir(parents=True, exist_ok=True)
    addon_id = "rice-theme@local"
    version = "2.0.0"
    theme_colors = firefox_theme_colors(bg, bg2, bg3, muted, accent, fg, border)
    # An extension, not a static theme: Firefox only runs the background script
    # for extensions, and that script is what restyles an already-open window.
    manifest = {
        "manifest_version": 3,
        "name": "Rice",
        "version": version,
        "browser_specific_settings": {
            "gecko": {"id": addon_id, "strict_min_version": "128.0"}
        },
        "permissions": ["theme", "nativeMessaging"],
        "background": {"scripts": ["background.js"]},
    }
    xpi_path = theme_dir / f"{addon_id}.xpi"
    import zipfile

    with zipfile.ZipFile(xpi_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("manifest.json", json.dumps(manifest, indent=2))
        zf.writestr("background.js", FIREFOX_BACKGROUND)
        zf.writestr("colors.json", json.dumps(theme_colors))
    install_firefox_host()

    import time
    import uuid

    now_ms = int(time.time() * 1000)
    profiles = [
        HOME / ".config/mozilla/firefox/wh2fn9ni.dev-edition-default",
        HOME / ".config/mozilla/firefox/j1fhq2y8.default-release",
        HOME / ".config/mozilla/firefox/044cb1z1.default",
    ]
    for profile in profiles:
        if not profile.is_dir():
            continue
        ext_dir = profile / "extensions"
        ext_dir.mkdir(parents=True, exist_ok=True)
        dest = ext_dir / f"{addon_id}.xpi"
        dest.write_bytes(xpi_path.read_bytes())

        store = profile / "extensions.json"
        if not store.is_file():
            continue
        try:
            data = json.loads(store.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            continue
        addons = data.get("addons")
        if not isinstance(addons, list):
            continue
        for addon in addons:
            # Keep the built-in dark theme as a fallback. The Rice extension
            # paints over it as soon as its background script connects.
            if addon.get("id") == "firefox-compact-dark@mozilla.org":
                addon["active"] = True
                addon["userDisabled"] = False
            elif addon.get("type") == "theme":
                addon["active"] = False
                addon["userDisabled"] = True
        existing = next((a for a in addons if a.get("id") == addon_id), None)
        uri = f"jar:file://{dest}!/"
        if existing is None:
            addons.append(
                {
                    "id": addon_id,
                    "syncGUID": "{" + str(uuid.uuid4()) + "}",
                    "version": "2.0.0",
                    "type": "extension",
                    "loader": None,
                    "manifestVersion": 3,
                    "defaultLocale": {"name": "Rice"},
                    "visible": True,
                    "active": True,
                    "userDisabled": False,
                    "appDisabled": False,
                    "embedderDisabled": False,
                    "installDate": now_ms,
                    "updateDate": now_ms,
                    "applyBackgroundUpdates": 1,
                    "path": str(dest),
                    "skinnable": False,
                    "softDisabled": False,
                    "foreignInstall": True,
                    "strictCompatibility": False,
                    "locales": [],
                    "targetApplications": [
                        {"id": "toolkit@mozilla.org", "minVersion": "128.0", "maxVersion": "*"}
                    ],
                    "targetPlatforms": [],
                    "seen": True,
                    "dependencies": [],
                    "icons": {},
                    "blocklistState": 0,
                    "hidden": False,
                    "rootURI": uri,
                    "location": "app-profile",
                }
            )
        else:
            existing.update(
                {
                    "active": True,
                    "userDisabled": False,
                    "appDisabled": False,
                    "updateDate": now_ms,
                    "path": str(dest),
                    "rootURI": uri,
                    "version": "2.0.0",
                    "type": "extension",
                }
            )
        store.write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")


def main() -> None:
    merge_vscode()
    merge_fastfetch()
    merge_heroic()
    merge_bottom()
    patch_hyprlock()
    ensure_mpv_include()
    ensure_btop_theme()
    install_firefox_theme()


if __name__ == "__main__":
    main()
