if status is-interactive
    if not set -q FASTFETCH_RAN
        set -gx FASTFETCH_RAN 1
        fastfetch
        echo
    end
end

# Remove default greeting
set -g fish_greeting ""

# --- Syntax Highlighting ---
# These name kitty's ANSI slots, which are rewritten from the wallpaper.
# Bright black is the muted wallpaper tone. Quotes stay yellow so a commit
# message cannot blend into the background.
set -g fish_color_normal normal
set -g fish_color_command white --bold
set -g fish_color_param cyan
set -g fish_color_keyword magenta
set -g fish_color_quote yellow
set -g fish_color_redirection brcyan
set -g fish_color_end blue
set -g fish_color_operator brmagenta
set -g fish_color_escape brblue
set -g fish_color_comment brblack
set -g fish_color_autosuggestion brblack
set -g fish_color_selection white --background=brblack
set -g fish_color_search_match black --background=green
set -g fish_color_error red

# --- Prompt ---
# Foreground and the muted wallpaper tone, the same pair the desktop uses.
function fish_prompt
    set -l git_branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)

    set_color white
    echo -n "╭─ "

    set_color -b white black
    echo -n " "(whoami)" "
    set_color -b brblack white
    echo -n ""

    set_color -b brblack black
    echo -n "   "(prompt_pwd)" "

    if test -n "$git_branch"
        set_color -b white brblack
        echo -n ""
        set_color -b white black
        echo -n "  $git_branch "
        set_color normal
        set_color white
        echo -n ""
    else
        set_color -b white brblack
        echo -n ""
        set_color -b white black
        echo -n " "(date +'%H:%M')" "
        set_color normal
        set_color white
        echo -n ""
    end

    echo
    set_color white
    echo -n "╰─ ❯ "
    set_color normal
end

function fish_right_prompt
end

function update-all
    echo "==> Updating Official Arch Packages..."
    sudo pacman -Syu
    echo "==> Updating AUR Packages..."
    yay -Syu --noconfirm
    echo "==> Updating Flatpaks..."
    flatpak update -y
    echo "==> Checking Firmware & BIOS Updates..."
    fwupdmgr refresh
    fwupdmgr update -y
    echo "==> Updating Cargo Packages..."
    cargo install-update -a
    echo "==> Cleaning Package Cache..."
    paccache -r
    echo "==> System Update Complete!"
end