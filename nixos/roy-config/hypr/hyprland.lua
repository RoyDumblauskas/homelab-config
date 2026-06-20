-- Import files
-- require("relative.path")

-- monitors
hl.monitor({
  output = "",
  mode = "preferred",
  position = "auto",
  scale = 1
})

hl.monitor({
  output = "DP-1",
  mode = "3840x2160@60",
  position = "auto",
  scale = 1.5
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "2560x1440@59.95",
  position = "auto-left",
  scale = 1
})

-- variables
local terminal    = "alacritty"
local fileManager = "dolphin"
local menu        = "wofi --show=drun --prompt='Search Programs'"

-- on start
hl.on("hyprland.start", function()
  hl.exec_cmd("waybar")
  hl.exec_cmd(terminal)
end)

-- env vars
hl.env("HYPRCURSOR_THEME", "rose-pine-hyprcursor")
hl.env("HYPRCURSOR_SIZE", "18")

-- look and feel
hl.config({
  general = {
    gaps_in = 0,
    gaps_out = 0,

    border_size = 1,

    col = {
      active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
      inactive_border = "rgba(595959aa)"
    },

    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle"
  },

  decoration = {
    rounding = 0,

    active_opacity = 1.0,
    inactive_opacity = 1.0,

    shadow = { enabled = false },
    blur = { enabled = false }
  },

  animations = {
    enabled = false
  }
})

-- dwindle
hl.config({
  dwindle = {
    preserve_split = true
  }
})

-- master
hl.config({
  master = {
    new_status = "master",
  },
})

-- misc
hl.config({
  misc = {
    force_default_wallpaper = 0,
    disable_hyprland_logo = true,
    disable_splash_rendering = true
  }
})

-- input
hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",

    follow_mouse = 1,
    sensitivity = 0,

    touchpad = {
      natural_scroll = false
    }
  }
})

-- keybinds
local mainMod = "SUPER"

hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("firefox"))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + Space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + M",
  hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- move focus
hl.bind(mainMod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + j", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + l", hl.dsp.focus({ direction = "right" }))

-- switch/move workspaces
for i = 1, 10 do
  local key = i % 10
  hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
  hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- focus on unfocused monitor (2 monitors only)
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus-unfocused-monitor.sh"))

-- move workspace to unfocused monitor (two monitors only)
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/move-workspace-to-unfocused-monitor.sh"))

-- screenshot
hl.bind(mainMod .. " + SHIFT + s",
  hl.dsp.exec_cmd('grim -g "$(slurp -d)" - | tee /home/$USER/dl/$(date +"%F_%T").png | wl-copy'))

-- fullscreen
hl.bind(mainMod .. " + SHIFT + f", hl.dsp.window.fullscreen({ action = "toggle" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
  { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Fix some dragging issues with XWayland
hl.window_rule({
  name     = "fix-xwayland-drags",
  match    = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },

  no_focus = true,
})
