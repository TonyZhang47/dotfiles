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
# These name kitty's ANSI slots, which follow the wallpaper. Yellow, blue, and
# magenta are light enough for the dark prompt text. Bright black is the muted
# text color. Quotes use yellow so a commit message cannot blend into the background.
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
# Invalid input stays red in every theme so it cannot blend in.
set -g fish_color_error f7768e

# --- Prompt ---
# Recreates the Oh-My-Posh "viet" prompt from ViegPhunt's Dotfiles, in fish, so
# it follows the wallpaper palette instead of a hardcoded Catppuccin mocha.
# Pokemon-colorscripts on startup is intentionally omitted.
function fish_prompt
    set -l git_branch (command git rev-parse --abbrev-ref HEAD 2>/dev/null)

    set_color white
    echo -n "╭─ "

    # Username pill
    set_color -b yellow black
    echo -n " "(whoami)" "
    set_color -b blue yellow
    echo -n ""

    # Path pill
    set_color -b blue black
    echo -n "   "(prompt_pwd)" "

    if test -n "$git_branch"
        set_color -b magenta blue
        echo -n ""
        set_color -b magenta black
        echo -n "  $git_branch "
        set_color normal
        set_color magenta
        echo -n ""
    else
        set_color -b magenta blue
        echo -n ""
        set_color -b magenta black
        echo -n " ♥ "(date +'%H:%M')" "
        set_color normal
        set_color magenta
        echo -n ""
    end

    echo
    set_color white
    echo -n "╰─ "
    set_color green
    echo -n "❯"
    set_color normal
    echo -n " "
end

function fish_right_prompt
end
