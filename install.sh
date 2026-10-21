#!/usr/bin/env bash
# Install this Hyprland desktop on an existing Arch Linux system.
# Run from your user account: ./install.sh
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MODE=""
ASSUME_YES=0
BACKUP=""

PACMAN_PKGS=(
  hyprland hypridle hyprlock hyprsunset hyprpolkitagent hyprpaper hyprshot
  xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk
  kitty rofi nemo mako
  playerctl brightnessctl grim slurp wl-clipboard satty
  pipewire pipewire-alsa pipewire-pulse wireplumber pavucontrol
  cava gtk4 gtk4-layer-shell gjs dart-sass
  gobject-introspection imagemagick inotify-tools curl
  ttf-iosevka-nerd ttf-jetbrains-mono-nerd
  noto-fonts noto-fonts-cjk noto-fonts-emoji adwaita-fonts
  adw-gtk-theme
  networkmanager bluez bluez-utils
  starship fastfetch neovim fish
  qt6ct qt5ct nwg-look nwg-displays
  power-profiles-daemon
  imv mpv btop bluetui
  awww matugen firefox-developer-edition polkit
  thunar thunar-volman thunar-archive-plugin
)

# Present in Chaotic-AUR on the machine this rice came from.
# pacman is used when the package is already visible; otherwise yay builds it.
AUR_PKGS=(
  aylurs-gtk-shell
  libastal-git
  libastal-4-git
  spotify
  bibata-cursor-theme
)

CONFIG_DIRS=(
  ags bottom btop cava easyeffects fastfetch firefox-theme fish fontconfig
  ghostty gtk-3.0 gtk-4.0 hypr imv kitty live-wallpapers mako matugen mpv
  nemo nmrs nvim nwg-displays nwg-look qt5ct qt6ct rice rofi rog satty
  spicetify Thunar xfce4 xsettingsd yazi zsh
)

CONFIG_FILES=(
  kdeglobals mimeapps.list pavucontrol.ini starship.toml user-dirs.dirs user-dirs.locale
)

usage() {
  cat <<EOF
Usage: ./install.sh [--full | --configs | --packages] [--yes]

  --full       Install packages and copy configs
  --configs    Copy configs only
  --packages   Install packages only
  --yes        Accept the recommended prompts (Chaotic-AUR if needed,
               keep Dvorak, use the display's preferred mode)

With no flags, the script asks what to do.
EOF
}

log() { printf '\n==> %s\n' "$*"; }

confirm() {
  local prompt=$1 default=${2:-n} reply
  if [[ "$ASSUME_YES" == 1 || ! -t 0 ]]; then
    [[ "$default" == y ]]
    return
  fi
  if [[ "$default" == y ]]; then
    read -rp "$prompt [Y/n] " reply || true
    [[ -z "${reply:-}" || "$reply" =~ ^[Yy] ]]
  else
    read -rp "$prompt [y/N] " reply || true
    [[ "${reply:-}" =~ ^[Yy] ]]
  fi
}

need_arch() {
  if [[ "$(id -u)" -eq 0 ]]; then
    echo "Run this as your user, not as root. The script will call sudo for packages." >&2
    exit 1
  fi
  if ! command -v pacman >/dev/null 2>&1 || [[ ! -f /etc/arch-release ]]; then
    echo "This installer is for Arch Linux." >&2
    exit 1
  fi
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required." >&2
    exit 1
  fi
}

choose_mode() {
  if [[ -n "$MODE" ]]; then
    return
  fi
  if [[ ! -t 0 ]]; then
    echo "Pass --full, --configs, or --packages." >&2
    exit 1
  fi
  cat <<EOF

Install this Hyprland desktop.

  1) Full install     packages and configs
  2) Configs only     copy the layout, leave packages alone
  3) Packages only    install software, leave configs alone

EOF
  local choice
  read -rp "Choice [1]: " choice || true
  case "${choice:-1}" in
    1|full) MODE=full ;;
    2|configs) MODE=configs ;;
    3|packages) MODE=packages ;;
    *) echo "Unknown choice." >&2; exit 1 ;;
  esac
}

enable_chaotic() {
  if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
    return
  fi
  local missing=0 pkg
  for pkg in "${AUR_PKGS[@]}"; do
    if ! pacman -Si "$pkg" &>/dev/null; then
      missing=1
      break
    fi
  done
  if [[ "$missing" -eq 0 ]]; then
    return
  fi
  log "Chaotic-AUR"
  echo "AGS libraries and Spotify are published on Chaotic-AUR."
  echo "Without that repo, yay will build them from the AUR."
  if ! confirm "Enable Chaotic-AUR?" y; then
    return
  fi
  sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
  sudo pacman-key --lsign-key 3056513887B78AEB
  sudo pacman -U --noconfirm \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
    'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
  if ! grep -q '^\[chaotic-aur\]' /etc/pacman.conf; then
    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf >/dev/null
  fi
  sudo pacman -Sy
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi
  log "Installing yay"
  sudo pacman -S --needed --noconfirm git base-devel
  local tmp
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

gpu_packages() {
  local line pkgs=()
  line=$(lspci -nn 2>/dev/null | grep -Ei 'vga|3d|display' || true)
  if grep -qiE 'amd|ati|radeon' <<<"$line"; then
    pkgs+=(mesa vulkan-radeon)
  fi
  if grep -qi intel <<<"$line"; then
    pkgs+=(mesa vulkan-intel intel-media-driver)
  fi
  if grep -qi nvidia <<<"$line"; then
    echo "NVIDIA hardware detected." >&2
    if confirm "Install nvidia-open-dkms and nvidia-utils?" n; then
      pkgs+=(nvidia-open-dkms nvidia-utils)
    else
      echo "Skipping the NVIDIA driver. Install it yourself if the session has no picture." >&2
    fi
  fi
  if [[ ${#pkgs[@]} -eq 0 ]]; then
    pkgs+=(mesa)
  fi
  printf '%s\n' "${pkgs[@]}" | awk '!seen[$0]++'
}

install_packages() {
  log "Packages"
  enable_chaotic
  local gpu extra=() pkg
  mapfile -t gpu < <(gpu_packages)
  sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}" "${gpu[@]}"
  for pkg in "${AUR_PKGS[@]}"; do
    if pacman -Si "$pkg" &>/dev/null; then
      sudo pacman -S --needed --noconfirm "$pkg"
    else
      extra+=("$pkg")
    fi
  done
  if [[ ${#extra[@]} -gt 0 ]]; then
    install_yay
    yay -S --needed --noconfirm "${extra[@]}"
  fi
  if systemctl is-active --quiet systemd-networkd || systemctl is-active --quiet iwd; then
    echo "A network daemon is already running. NetworkManager is installed for the Wi-Fi menu and was left stopped."
  else
    sudo systemctl enable --now NetworkManager.service
  fi
  sudo systemctl enable --now bluetooth.service || true
}

backup_path() {
  local src=$1 rel
  [[ -e "$src" ]] || return 0
  mkdir -p "$BACKUP"
  rel=${src#"$HOME"/}
  mkdir -p "$BACKUP/$(dirname "$rel")"
  mv "$src" "$BACKUP/$rel"
}

copy_configs() {
  log "Configs"
  if [[ -e "$HOME/.config/hypr/hyprland.lua" ]]; then
    echo "Existing Hyprland config found at ~/.config/hypr."
    if ! confirm "Replace the desktop configs shipped in this repo? A backup is kept." y; then
      echo "Config copy skipped."
      return 1
    fi
  fi
  BACKUP="$HOME/.local/share/hyprland-rice-backup-$(date +%Y%m%d-%H%M%S)"
  local dir dest
  for dir in "${CONFIG_DIRS[@]}"; do
    [[ -d "$ROOT/config/$dir" ]] || continue
    dest="$HOME/.config/$dir"
    backup_path "$dest"
    mkdir -p "$(dirname "$dest")"
    cp -a "$ROOT/config/$dir" "$dest"
  done
  mkdir -p "$HOME/.config/wallpapers"
  cp -a "$ROOT/config/wallpapers/." "$HOME/.config/wallpapers/"
  mkdir -p "$HOME/.config/systemd/user"
  cp -a "$ROOT/config/systemd/user/." "$HOME/.config/systemd/user/"
  mkdir -p "$HOME/.config/mozilla/native-messaging-hosts" \
           "$HOME/.mozilla/native-messaging-hosts"
  cp -a "$ROOT/config/mozilla/native-messaging-hosts/rice_theme.json" \
    "$HOME/.config/mozilla/native-messaging-hosts/rice_theme.json"
  cp -a "$ROOT/config/mozilla/native-messaging-hosts/rice_theme.json" \
    "$HOME/.mozilla/native-messaging-hosts/rice_theme.json"
  local file
  for file in "${CONFIG_FILES[@]}"; do
    [[ -f "$ROOT/config/$file" ]] || continue
    backup_path "$HOME/.config/$file"
    cp -a "$ROOT/config/$file" "$HOME/.config/$file"
  done
  if [[ -f "$HOME/.gtkrc-2.0" ]]; then
    backup_path "$HOME/.gtkrc-2.0"
  fi
  cp -a "$ROOT/home/.gtkrc-2.0" "$HOME/.gtkrc-2.0"
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share/fonts"
  cp -a "$ROOT/local-bin/ags" "$HOME/.local/bin/ags"
  cp -a "$ROOT/local-bin/spotify" "$HOME/.local/bin/spotify"
  cp -a "$ROOT/local-share/fonts/." "$HOME/.local/share/fonts/"
  rewrite_home
  tune_hyprland
  chmod +x "$HOME/.local/bin/ags" "$HOME/.local/bin/spotify"
  find "$HOME/.config/ags/scripts" "$HOME/.config/hypr/scripts" "$HOME/.config/rice" \
    -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} +
  command -v fc-cache >/dev/null && fc-cache -f >/dev/null || true
  if [[ -n "$BACKUP" && -d "$BACKUP" ]]; then
    echo "Previous configs were moved to $BACKUP"
  fi
}

rewrite_home() {
  [[ "$HOME" == /home/ping ]] && return 0
  local paths=() dir file
  for dir in "${CONFIG_DIRS[@]}" wallpapers; do
    [[ -e "$HOME/.config/$dir" ]] && paths+=("$HOME/.config/$dir")
  done
  for file in "${CONFIG_FILES[@]}"; do
    [[ -f "$HOME/.config/$file" ]] && paths+=("$HOME/.config/$file")
  done
  paths+=(
    "$HOME/.gtkrc-2.0"
    "$HOME/.local/bin/ags"
    "$HOME/.local/bin/spotify"
    "$HOME/.config/systemd/user/hyprsunset.service"
    "$HOME/.config/systemd/user/wallpaper-watch.service"
    "$HOME/.config/mozilla/native-messaging-hosts/rice_theme.json"
    "$HOME/.mozilla/native-messaging-hosts/rice_theme.json"
  )
  local f
  while IFS= read -r -d '' f; do
    sed -i "s|/home/ping|$HOME|g" "$f"
  done < <(grep -rIlZ --binary-files=without-match '/home/ping' "${paths[@]}" || true)
}

tune_hyprland() {
  local file="$HOME/.config/hypr/hyprland.lua"
  [[ -f "$file" ]] || return 0
  echo
  echo "Keyboard: this rice uses Dvorak. The key letters below follow that layout."
  if confirm "Keep Dvorak?" y; then
    :
  else
    sed -i 's/kb_variant = "dvorak"/kb_variant = ""/' "$file"
    echo "Hyprland keyboard variant set to US QWERTY."
  fi
  echo
  echo "Monitor: the author's panel is 2880x1800 @ 120Hz, scale 1.5."
  if confirm "Use this display's preferred mode and scale 1 instead?" y; then
    sed -i \
      -e 's/mode     = "2880x1800@120"/mode     = "preferred"/' \
      -e 's/scale    = "1.5"/scale    = "1"/' \
      "$file"
    echo "Monitor set to preferred mode, scale 1. Edit ~/.config/hypr/hyprland.lua if the picture is the wrong size."
  fi
}

enable_user_services() {
  log "User services"
  systemctl --user daemon-reload || true
  systemctl --user enable wallpaper-watch.service hyprsunset.service || true
  systemctl --user enable pipewire.service pipewire-pulse.service wireplumber.service || true
  systemctl --user enable hyprpolkitagent.service || true
  systemctl --user start wallpaper-watch.service hyprsunset.service \
    pipewire.service pipewire-pulse.service wireplumber.service \
    hyprpolkitagent.service || echo "User services are enabled. They start with the graphical session."
}

setup_spotify() {
  [[ -x /opt/spotify/spotify ]] || return 0
  [[ -x "$HOME/.config/ags/scripts/setup-spotify.sh" ]] || return 0
  log "Spotify theme"
  if confirm "Install the wallpaper-colored Spotify theme (Spicetify)?" y; then
    "$HOME/.config/ags/scripts/setup-spotify.sh" || echo "Spotify theme setup did not finish. Run ~/.config/ags/scripts/setup-spotify.sh later."
  fi
}

cpu_boost() {
  [[ -x "$HOME/.config/rice/install-cpu-boost-off.sh" ]] || return 0
  echo
  echo "Optional: keep CPU boost off across boot and sleep. This was written for an ASUS laptop."
  if confirm "Install that tweak?" n; then
    sudo "$HOME/.config/rice/install-cpu-boost-off.sh"
  fi
}

finish() {
  cat <<EOF

Desktop files are in place.

Start Hyprland from a TTY with:  Hyprland
Or pick the Hyprland session in your display manager.

The shell prompt lives in fish. Your login shell was left as it is.
Run fish, or change it with:  chsh -s /usr/bin/fish

Super+comma opens Kitty. Super+E opens Nemo. Super+Space opens Rofi.
Super+Shift+T picks a wallpaper. Wallpapers live in ~/.config/wallpapers.
Super+C is the control center. Super+H is settings. Super+L locks.

The binds are written for Dvorak unless you switched the layout during install.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) MODE=full ;;
    --configs) MODE=configs ;;
    --packages) MODE=packages ;;
    --yes) ASSUME_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

need_arch
choose_mode

case "$MODE" in
  full)
    install_packages
    if copy_configs; then
      enable_user_services
      setup_spotify
      cpu_boost
      finish
    fi
    ;;
  configs)
    if copy_configs; then
      enable_user_services
      setup_spotify
      finish
    fi
    ;;
  packages)
    install_packages
    ;;
esac
