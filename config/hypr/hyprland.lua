-- This is an example Hyprland Lua config file.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/configuring/

-- Please note not all available settings / options are set here.
-- For a full list, see the wiki

-- You can (and should!!) split this configuration into multiple files
-- Create your files separately and then require them like this:
-- require("myColors")


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/
hl.monitor({
    output   = "",
    mode     = "2880x1800@120",
    position = "auto",
    scale    = "1.5",
})

-- XWayland apps (Spotify, Discord) ignore the monitor scale and come up
-- the wrong size. Render them at 1x and let Hyprland scale the window.
hl.config({
    xwayland = {
        force_zero_scaling = true,
    },
})


---------------------
---- MY PROGRAMS ----
---------------------

-- Set programs that you use
local terminal    = "kitty"
local fileManager = "nemo"
local browser = "firefox-developer-edition"
local music = "spotify"
local notion = "firefox-developer-edition https://calendar.notion.so/"

local launcher        = "rofi -show drun -show-icons"
local runner = "rofi -show run"



-------------------
---- AUTOSTART ----
-------------------



-- See https://wiki.hypr.land/configuring/core/autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
hl.on("hyprland.start", function () 
 -- hl.exec_cmd(terminal)
 -- hl.exec_cmd("nm-applet")

--wallpaper
hl.exec_cmd("awww-daemon > /dev/null 2>&1 &")
hl.exec_cmd("/home/ping/.config/ags/scripts/restore-wallpaper.sh")
-- AGS draws the control-center, settings, and wallpaper picker overlays.
hl.exec_cmd("pgrep -f '/.local/bin/ags run' >/dev/null || setsid -f /home/ping/.local/bin/ags run /home/ping/.config/ags/app.tsx >/dev/null 2>&1")

hl.exec_cmd("playerctld daemon")
hl.exec_cmd("setsid -f /home/ping/.config/hypr/scripts/set-cursor.sh >/dev/null 2>&1")
hl.exec_cmd("systemctl --user start hyprpolkitagent")
hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE DISPLAY XDG_RUNTIME_DIR")
hl.exec_cmd("systemctl --user start hyprsunset.service")
hl.exec_cmd("setsid -f /home/ping/.config/ags/scripts/restore-warm-light.sh >/dev/null 2>&1")

hl.exec_cmd("pidof hypridle || setsid -f hypridle -c /home/ping/.config/hypr/hypridle.conf >/dev/null 2>&1")
hl.exec_cmd("pgrep -f '/ags/scripts/watch-wallpapers.sh' >/dev/null || setsid -f /home/ping/.config/ags/scripts/watch-wallpapers.sh >/dev/null 2>&1")
hl.exec_cmd("pgrep -f '/hypr/scripts/clip-history.py watch' >/dev/null || setsid -f /home/ping/.config/hypr/scripts/clip-history.py watch >/dev/null 2>&1")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/

hl.env("XCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_THEME", "Bibata-Modern-Ice")
hl.env("HYPRCURSOR_SIZE", "20")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")

-----------------------
----- PERMISSIONS -----
-----------------------

-- See https://wiki.hypr.land/configuring/core/advanced-configuration/permissions/
-- Please note permission changes here require a Hyprland restart and are not applied on-the-fly
-- for security reasons

-- hl.config({
--   ecosystem = {
--     enforce_permissions = true,
--   },
-- })

-- hl.permission("/usr/(bin|local/bin)/grim", "screencopy", "allow")
-- hl.permission("/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow")
-- hl.permission("/usr/(bin|local/bin)/hyprpm", "plugin", "allow")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
-- Live Super+H settings. Defaults match the rice; ~/.config/hypr/user-settings.lua
-- overrides them so you do not have to edit this file.
local user = {
    sensitivity = 0.5,
    scroll_factor = 0.2,
    gaps_in = 8,
    gaps_out = 18,
    rounding = 14,
    inactive_opacity = 0.9,
    animations = true,
    accel_profile = "flat",
}
do
    local chunk = loadfile("/home/ping/.config/hypr/user-settings.lua")
    if type(chunk) == "function" then
        local ok, data = pcall(chunk)
        if ok and type(data) == "table" then
            for k, v in pairs(data) do
                user[k] = v
            end
        end
    end
end

-- Zenities look. Keybinds below are unchanged.
hl.config({
    general = {
        gaps_in  = user.gaps_in,
        gaps_out = user.gaps_out,

        border_size = 0,

        resize_on_border = false,
        extend_border_grab_area = 0,
        hover_icon_on_border = false,
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding = user.rounding,

        active_opacity   = 1.0,
        inactive_opacity = user.inactive_opacity,

        blur = {
            enabled         = true,
            vibrancy        = 0.8,
            contrast        = 0.6,
            size            = 6,
            passes          = 3,
            ignore_opacity  = true,
            new_optimizations = true,
        },

        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
        },
    },

    cursor = {
        no_hardware_cursors = true,
    },

    animations = {
        enabled = user.animations,
    },
})

hl.curve("basic", { type = "bezier", points = { {0.05, 0.8}, {0.1, 1} } })
hl.curve("easeOut", { type = "bezier", points = { {0.22, 1.0}, {0.36, 1.0} } })
hl.curve("easeInOut", { type = "bezier", points = { {0.45, 0.0}, {0.35, 1.0} } })

hl.animation({ leaf = "global",      enabled = true, speed = 8, bezier = "default" })
-- Overlay panels slide from the edge they are anchored
-- to. Slow enough to read, and the exit is slower than the entrance.
hl.animation({ leaf = "layersIn",    enabled = true, speed = 4.5, bezier = "easeOut",   style = "slide" })
hl.animation({ leaf = "layersOut",   enabled = true, speed = 5.5, bezier = "easeInOut", style = "slide" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 4.5, bezier = "easeOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 5.5, bezier = "easeInOut" })
hl.animation({ leaf = "windows",     enabled = true, speed = 2.6, bezier = "easeOut" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 2.8, bezier = "easeOut", style = "popin 92%" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 2.6, bezier = "easeOut", style = "popin 92%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.6, bezier = "easeOut" })
hl.animation({ leaf = "fade",        enabled = true, speed = 2.4, bezier = "easeOut" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 3.2, bezier = "easeOut", style = "slide" })

-- Ref https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })

-- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/ for more
hl.config({
    dwindle = {
        preserve_split = true,
        force_split = 2, -- second window always to the right (side by side)
    },
})

-- See https://wiki.hypr.land/configuring/layouts/master-layout/ for more
hl.config({
    master = {
        new_status = "master",
    },
})

-- See https://wiki.hypr.land/configuring/layouts/scrolling-layout/ for more
hl.config({
    scrolling = {
        fullscreen_on_one_column = true,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper = 1,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
        disable_splash_rendering = true,
        key_press_enables_dpms = true,
    },
})


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "dvorak",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",
repeat_rate = 25,
repeat_delay = 300,
        follow_mouse = 1,

        sensitivity = user.sensitivity, -- -1.0 - 1.0, 0 means no modification.
        accel_profile = user.accel_profile,
        force_no_accel = false,
        touchpad = {
            natural_scroll = false,
            scroll_factor = user.scroll_factor,
        },
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/configuring/core/devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})


---------------------
---- KEYBINDINGS ----
---------------------

--bind = CTRL, 1, workspace, 1
--bind = CTRL, 2, workspace, 2
--bind = CTRL, 3, workspace, 3
--bind = CTRL, 4, workspace, 4
--bind = CTRL, 5, workspace, 5
--bind = CTRL, 6, workspace, 6
--bind = CTRL, 7, workspace, 7
--bind = CTRL, 8, workspace, 8
--bind = CTRL, 9, workspace, 9


local mainMod = "SUPER" -- Sets "Windows" key as main modifier
local secondMod = "SUPER + SHIFT"

-- Example binds, see https://wiki.hypr.land/configuring/core/binds/ for more
hl.bind(mainMod .. " + comma", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + apostrophe", hl.dsp.window.close())

--Screenshot
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/screenshot-bind.sh clip"))
hl.bind(secondMod .. " + S", hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/screenshot-bind.sh save"))
hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd(notion))

--hl.bind(mainMod .. " + G", hl.dsp.exec_cmd("supergfxctl -m Integrated"))
--hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("supergfxctl -m Hybrid"))

hl.bind(secondMod .. " + apostrophe", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + J", hl.dsp.exec_cmd(music))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(launcher))
hl.bind(secondMod .. " + SPACE", hl.dsp.exec_cmd(runner))
hl.bind(mainMod .. " + X", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
--hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle only

-- Wallpaper picker: live GIFs plus static stills.
hl.bind("SUPER + SHIFT+ T", hl.dsp.exec_cmd("/home/ping/.local/bin/ags toggle wallpaper"))

-- Show or hide the right-side control center.
hl.bind("SUPER + C", hl.dsp.exec_cmd("/home/ping/.local/bin/ags toggle control-center"))

-- Settings popup (cursor, gaps, rounding). Values persist outside this file.
hl.bind("SUPER + H", hl.dsp.exec_cmd("/home/ping/.local/bin/ags toggle settings"))

-- Clipboard history. Super+V is still focus-down.
hl.bind("SUPER + CTRL + V", hl.dsp.exec_cmd("/home/ping/.config/hypr/scripts/clip-history.py pick"))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + M",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + Z", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + W",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + V",  hl.dsp.focus({ direction = "down" }))

hl.bind(secondMod .. " + M", hl.dsp.window.move({direction = "left"}))
hl.bind(secondMod .. " + Z", hl.dsp.window.move({direction = "right"}))
hl.bind(secondMod .. " + W", hl.dsp.window.move({direction = "up"}))
hl.bind(secondMod .. " + V", hl.dsp.window.move({direction = "down"}))


-- Super+1..9 and Super+0 always exist, matching the dashboard pills.
for i = 1, 10 do
    hl.workspace_rule({
        workspace  = tostring(i),
        persistent = true,
    })
end

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
-- Super+0 is workspace 10, shown as "0" on the dashboard.
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end

-- Scratchpad (special workspace "magic")
hl.bind(mainMod .. " + N",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "special:magic" }))

-- Lock the session
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/lock.sh"))

-- Alt+Tab swaps the two most recent apps on this workspace.
-- Super+Tab lists every window here so you can jump to any of them.
hl.bind("ALT + TAB", hl.dsp.exec_cmd("/home/ping/.config/hypr/scripts/alt-tab.py"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("/home/ping/.config/hypr/scripts/window-switcher.py"))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Super + click drag moves. Super + Shift + click drag resizes.
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(secondMod .. " + mouse:272", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/volume-key.sh up"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/volume-key.sh down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/volume-key.sh mute"), { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/mic-key.sh"), { locked = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/brightness-key.sh up"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/brightness-key.sh down"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/media-key.sh next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/media-key.sh toggle"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/media-key.sh toggle"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("/home/ping/.config/ags/scripts/media-key.sh prev"), { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

-- Example window rules that are useful

local suppressMaximizeRule = hl.window_rule({
    -- Ignore maximize requests from all apps. You'll probably like this.
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

-- Apps tile so two windows sit side by side. Super+F maximizes inside the
-- tile; gaps_out keeps a wallpaper frame around even a single "fullscreen"
-- window. Empty-class XWayland helpers stay unmatched.

-- New GUI windows open floating and centered, about half the screen.
-- Super+X tiles them side by side; Super+F maximizes inside the gaps.
hl.window_rule({
    name  = "spawn-float",
    match = { class = ".+" },
    float = true,
    center = true,
    size  = { "(monitor_w*0.52)", "(monitor_h*0.58)" },
})

hl.window_rule({
    name  = "spawn-float-initial",
    match = { initial_class = ".+" },
    float = true,
    center = true,
    size  = { "(monitor_w*0.52)", "(monitor_h*0.58)" },
})

-- If another float is already sitting at the same spawn spot, nudge this
-- one so the stack isn't a perfect overlay. If a window is already offset,
-- leave the new one centered.
local spawnCascadeOffset = 42
local spawnCascadeSlop = 24

local function spawnNear(pos, x, y)
    if pos == nil or pos.x == nil or pos.y == nil then return false end
    return math.abs(pos.x - x) <= spawnCascadeSlop and math.abs(pos.y - y) <= spawnCascadeSlop
end

local function spawnOtherFloats(w)
    local list
    if hl.get_workspace_windows ~= nil and w.workspace ~= nil then
        local ok, wins = pcall(hl.get_workspace_windows, w.workspace)
        if ok then list = wins end
    end
    if list == nil and hl.get_windows ~= nil then
        local ok, wins = pcall(hl.get_windows, { floating = true, mapped = true })
        if ok then list = wins end
    end
    return list or {}
end

hl.on("window.open", function(w)
    if w == nil then return end
    local class = string.lower(tostring(w.class or w.initial_class or ""))
    if class == "" or class == "rofi" or class == "hyprland-run" then return end

    if not w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "set", window = w }))
        hl.dispatch(hl.dsp.window.center({ window = w }))
    end

    local at = w.at
    if at == nil or at.x == nil or at.y == nil then return end

    local addr = tostring(w.address or "")
    local wsId = w.workspace and w.workspace.id or nil
    local coversCenter = false
    local alreadyOffset = false
    for _, other in ipairs(spawnOtherFloats(w)) do
        if other ~= nil and other.floating and tostring(other.address or "") ~= addr then
            local otherWs = other.workspace and other.workspace.id or nil
            if wsId == nil or otherWs == nil or otherWs == wsId then
                if spawnNear(other.at, at.x, at.y) then
                    coversCenter = true
                elseif spawnNear(other.at, at.x + spawnCascadeOffset, at.y + spawnCascadeOffset) then
                    alreadyOffset = true
                end
            end
        end
    end

    if coversCenter and not alreadyOffset then
        hl.dispatch(hl.dsp.window.move({
            window = w,
            x = spawnCascadeOffset,
            y = spawnCascadeOffset,
            relative = true,
        }))
    end
end)

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})


-- Layer rules also return a handle.
-- local overlayLayerRule = hl.layer_rule({
--     name  = "no-anim-overlay",
--     match = { namespace = "^my-overlay$" },
--     no_anim = true,
-- })
-- overlayLayerRule:set_enabled(false)

-- Hyprland-run windowrule
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})
