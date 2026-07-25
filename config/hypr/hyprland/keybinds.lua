local vars = require("variables")
local fn   = require("hyprland.functions")

local M = "SUPER"

-- Launcher
hl.bind("SUPER + SUPER_L", hl.dsp.global("caelestia:launcher"), { release = true })

-- Apps
hl.bind(M .. " + Return", hl.dsp.exec_cmd(vars.terminal))
hl.bind(M .. " + T", hl.dsp.exec_cmd(vars.terminal))
hl.bind(M .. " + D", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(M .. " + Tab", hl.dsp.exec_cmd("rofi -show window"))
hl.bind(M .. " + SHIFT + D", hl.dsp.exec_cmd("rofi -show run"))
hl.bind(M .. " + C", hl.dsp.exec_cmd(vars.editor))
hl.bind(M .. " + O", hl.dsp.exec_cmd("opencode"))
hl.bind(M .. " + W", hl.dsp.exec_cmd(vars.browser))
hl.bind(M .. " + E", hl.dsp.exec_cmd(vars.fileExplorer))

-- Window management
hl.bind(M .. " + Q", hl.dsp.window.close())
hl.bind(M .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(M .. " + V", hl.dsp.window.float())
hl.bind(M .. " + SPACE", hl.dsp.exec_cmd("hyprctl dispatch focuswindow"))

hl.bind(M .. " + A", hl.dsp.exec_cmd("hyprctl dispatch focuscurrentorparent"))
hl.bind(M .. " + Z", hl.dsp.exec_cmd("hyprctl dispatch focuswindow"))

-- Layout
hl.bind(M .. " + H", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg orientationleft"))
hl.bind(M .. " + SHIFT + V", hl.dsp.exec_cmd("hyprctl dispatch layoutmsg orientationtop"))
hl.bind(M .. " + S", hl.dsp.layout("master"))
hl.bind(M .. " + SHIFT + W", hl.dsp.group.toggle())
hl.bind(M .. " + E", hl.dsp.layout("togglesplit"))

-- Scratchpad
hl.bind(M .. " + Minus", hl.dsp.workspace.toggle_special("special"))
hl.bind(M .. " + SHIFT + Minus", hl.dsp.window.move({ workspace = "special:special" }))

-- Lock screen
hl.bind(M .. " + SHIFT + X", hl.dsp.global("caelestia:lock"))
hl.bind(M .. " + SHIFT + M", hl.dsp.global("caelestia:lock"))

-- Workspace navigation
for i = 1, 10 do
    local key = i % 10
    hl.bind(M .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(M .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Focus navigation (vim style — j/k/l/; for left/down/up/right)
hl.bind(M .. " + J", hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + K", hl.dsp.focus({ direction = "down" }))
hl.bind(M .. " + L", hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + semicolon", hl.dsp.focus({ direction = "right" }))

-- Arrow keys focus
hl.bind(M .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(M .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(M .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(M .. " + right", hl.dsp.focus({ direction = "right" }))

-- Move window (vim style)
hl.bind(M .. " + SHIFT + J", hl.dsp.window.move({ direction = "left" }))
hl.bind(M .. " + SHIFT + K", hl.dsp.window.move({ direction = "down" }))
hl.bind(M .. " + SHIFT + L", hl.dsp.window.move({ direction = "up" }))
hl.bind(M .. " + SHIFT + semicolon", hl.dsp.window.move({ direction = "right" }))

-- Arrow keys move window
hl.bind(M .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(M .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
hl.bind(M .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(M .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))

-- Resize (i3-style: h/j/k/l via hyprctl dispatch resizeactive)
hl.bind(M .. " + ALT + H", hl.dsp.exec_cmd("hyprctl dispatch resizeactive -40 0"), { repeating = true })
hl.bind(M .. " + ALT + J", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 40"),  { repeating = true })
hl.bind(M .. " + ALT + K", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 0 -40"),  { repeating = true })
hl.bind(M .. " + ALT + L", hl.dsp.exec_cmd("hyprctl dispatch resizeactive 40 0"),  { repeating = true })

-- Screenshots
hl.bind("Print", hl.dsp.exec_cmd("/home/rigby/.config/hypr/scripts/screenshot.sh"))
hl.bind(M .. " + Print", hl.dsp.exec_cmd("/home/rigby/.config/hypr/scripts/screenshot.sh focused"))
hl.bind(M .. " + SHIFT + S", hl.dsp.exec_cmd("/home/rigby/.config/hypr/scripts/screenshot.sh area"))

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { locked = true, repeating = true })

-- Media
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Config reload / restart / exit
hl.bind(M .. " + SHIFT + C", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(M .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl dispatch hyprland.restart"))
hl.bind(M .. " + SHIFT + E", hl.dsp.exec_cmd("hyprctl dispatch hyprland.exit"))

-- Session / Misc (Caelestia shell)
hl.bind(vars.kbSession, hl.dsp.global("caelestia:session"))
hl.bind(vars.kbShowSidebar, hl.dsp.global("caelestia:sidebar"))

-- Game mode toggle
hl.bind(M .. " + SHIFT + G", hl.dsp.exec_cmd("/home/rigby/.config/hypr/scripts/gamemode.sh"))

-- Shell reload
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("/home/rigby/.config/hypr/panel/caelestia-launch.sh"), { release = true })
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("/home/rigby/.config/hypr/panel/caelestia-launch.sh"), { release = true })

-- Mouse bindings
hl.bind(M .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(M .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Workspace cycling via mouse
hl.bind(M .. " + mouse_down", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(M .. " + mouse_up", hl.dsp.focus({ workspace = "e+1" }))
