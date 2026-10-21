# Hyprland

An Arch Linux desktop built around [Hyprland](https://hyprland.org/), [AGS](https://aylurs.github.io/ags/), and colors taken from the wallpaper. Clone it, run one script, and the same layout, overlays, lock screen, and theme land in your home directory.

This is for an Arch system that already boots. The script installs the desktop packages and copies these configs. It does not partition a disk or create a user.

```bash
git clone https://github.com/TonyZhang47/Hyprland.git
cd Hyprland
./install.sh
```

## Install modes

`./install.sh` asks which mode to run. You can also pass a flag:

| Command | What it does |
| --- | --- |
| `./install.sh` | Asks, then installs |
| `./install.sh --full` | Packages and configs |
| `./install.sh --configs` | Configs only. Use this after `git pull` |
| `./install.sh --packages` | Packages only |
| add `--yes` | Keep Dvorak, use the display's preferred mode, enable Chaotic-AUR if those packages are missing |

The config copy moves anything it replaces into `~/.local/share/hyprland-rice-backup-<date>`.

During a full install the script also asks three questions:

1. **Chaotic-AUR.** AGS's libraries and Spotify are installed from Chaotic-AUR on the machine this rice came from. Saying yes adds that repo. Saying no builds the same packages with `yay`.
2. **Keyboard.** The binds below are Dvorak. You can keep that or switch Hyprland to US QWERTY.
3. **Monitor.** The author's panel is `2880x1800@120` at scale `1.5`. Other machines should take the preferred mode.

An optional prompt can install a CPU-boost-off tweak written for an ASUS laptop. Leave that off unless you want it.

## What the installer changes

* Installs the Hyprland session, AGS, Kitty, Nemo, Rofi, Mako, Firefox Developer Edition, and the tools the keybinds call.
* Detects AMD, Intel, and NVIDIA graphics. AMD and Intel get the open Mesa drivers. NVIDIA drivers are installed only if you say yes.
* Enables NetworkManager when no other network daemon is already running. The Wi-Fi menu talks to `nmcli`.
* Enables Bluetooth.
* Copies `config/` to `~/.config/`, the GTK 2 theme file to `~/.gtkrc-2.0`, `local-bin/` to `~/.local/bin`, and the Comfortaa lock-screen font to `~/.local/share/fonts`.
* Rewrites the author's home path (`/home/ping`) to your home directory.
* Enables the user services for wallpaper previews, hyprsunset, PipeWire, and the Hyprland polkit agent.

Spotify's login and editor, browser, and git profiles are not in this repo. A full install can set up the wallpaper-colored Spicetify theme after the Spotify package is installed. Log into Spotify yourself.

## Desktop

| Piece | Choice |
| --- | --- |
| Window manager | Hyprland, configured in Lua. Dwindle layout, blur, gaps, rounded corners |
| Overlays | AGS: control center, settings, wallpaper picker |
| Terminal | Kitty, JetBrainsMono Nerd Font |
| Launcher | Rofi |
| Files | Nemo (`Super+E`). Thunar config is included as well |
| Notifications | Mako |
| Lock screen | hyprlock, Comfortaa, cava bars |
| Wallpaper | `awww`. Files live in `~/.config/wallpapers` |
| Colors | matugen reads the wallpaper and recolors AGS, Kitty, Rofi, Mako, GTK, Qt, cava, btop, Neovim, Firefox, and Spotify |
| GTK | adw-gtk3-dark |
| Cursor | Bibata Modern Ice |
| Shell prompt | fish, with fastfetch on startup. The login shell is left unchanged |
| Editor | Neovim. Movement is remapped for Dvorak (`n` down, `e` up, `i` right, `u` insert) |
| Browser | Firefox Developer Edition |
| Music | Spotify, recolored with the wallpaper |

Ghostty config is included. The terminal bind opens Kitty.

## After it finishes

From a TTY:

```bash
Hyprland
```

A display manager can start the Hyprland session instead.

The styled prompt is fish:

```bash
fish
# or, to make it the login shell:
chsh -s /usr/bin/fish
```

`~/.local/bin` is put on `PATH` by the Hyprland config. `local-bin/ags` prefers the system `ags` binary and falls back to a copy under `~/.local/opt/ags`.

### Wallpaper

`Super+Shift+T` opens the picker. Drop images in `~/.config/wallpapers`. Choosing one runs matugen and the app theme scripts, so the rest of the desktop follows that picture.

### Update

```bash
cd Hyprland
git pull
./install.sh --configs
```

`--packages` installs anything new. `--full` does both.

### Black screen on login

The monitor line in `~/.config/hypr/hyprland.lua` may not match the panel. Switch to a TTY with `Ctrl+Alt+F3`, then either edit `mode` and `scale` in that file or run `./install.sh --configs` and accept the preferred mode.

`Super+Shift+apostrophe` leaves Hyprland.

## Keybinds

Dvorak is the layout these letters assume. If the installer switched you to QWERTY, the same letters are in the QWERTY positions.

| Keys | Action |
| --- | --- |
| `Super+comma` | Kitty |
| `Super+E` | Nemo |
| `Super+T` | Firefox Developer Edition |
| `Super+J` | Spotify |
| `Super+semicolon` | Notion calendar in Firefox |
| `Super+Space` | Rofi app launcher |
| `Super+Shift+Space` | Rofi run |
| `Super+C` | Control center |
| `Super+H` | Settings (gaps, blur, opacity, and the rest) |
| `Super+Shift+T` | Wallpaper picker |
| `Super+L` | Lock |
| `Super+S` | Screenshot region to the clipboard |
| `Super+Shift+S` | Screenshot region saved to `~/Pictures/Screenshots` |
| `Super+Ctrl+V` | Clipboard history |
| `Super+apostrophe` | Close window |
| `Super+Shift+apostrophe` | Exit Hyprland |
| `Super+X` | Float |
| `Super+F` or `Super+B` | Fullscreen |
| `Super+M` `Z` `W` `V` | Focus left, right, up, down |
| `Super+Shift+M` `Z` `W` `V` | Move the window that way |
| `Super+1` … `0` | Workspaces 1–10 |
| `Super+Shift+1` … `0` | Move the window to that workspace |
| `Super+N` | Scratchpad |
| `Alt+Tab` | Last two windows on this workspace |
| `Super+Tab` | Every window |
| `Super+scroll` | Next / previous workspace |
| `Super+drag` | Move a window |
| `Super+Shift+drag` | Resize a window |

Volume, mute, and brightness keys are bound to the matching hardware keys.

## Layout of this repo

```text
Hyprland/
├── config/                 # copied to ~/.config
│   ├── hypr/               # compositor, lock screen, idle, scripts
│   ├── ags/                # overlays and the scripts they call
│   ├── matugen/            # wallpaper color templates
│   ├── kitty/ rofi/ mako/  # programs themed from the wallpaper
│   ├── wallpapers/         # pictures the picker shows
│   └── systemd/user/       # wallpaper previews and hyprsunset
├── home/.gtkrc-2.0         # GTK 2 theme
├── local-bin/              # ags wrapper and the Spotify launcher
├── local-share/fonts/      # Comfortaa, used on the lock screen
└── install.sh
```

## Packages

Official repositories:

`hyprland` `hypridle` `hyprlock` `hyprsunset` `hyprpolkitagent` `hyprpaper` `hyprshot` `xdg-desktop-portal-hyprland` `xdg-desktop-portal-gtk` `kitty` `rofi` `nemo` `mako` `awww` `matugen` `firefox-developer-edition` `pipewire` `wireplumber` `cava` `satty` `grim` `slurp` `wl-clipboard` `playerctl` `brightnessctl` `adw-gtk-theme` `qt6ct` `nwg-look` `fish` `starship` `fastfetch` `neovim` `ttf-jetbrains-mono-nerd` `ttf-iosevka-nerd` `noto-fonts` `adwaita-fonts`

Chaotic-AUR, or the AUR through yay:

`aylurs-gtk-shell` `libastal-git` `libastal-4-git` `spotify` `bibata-cursor-theme`

`bibata-cursor-theme` is used from Chaotic-AUR here. If your pacman already sees that name, the script installs it with pacman.
