local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.font_size = 15.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE"

-- Cmd = navigate herdr workspaces (mirrors Ctrl = navigate agents).
-- The Cmd/super modifier can't travel through a terminal input stream, so instead of
-- forwarding Cmd itself we translate it into herdr's prefix sequence (Ctrl+Space, then Shift+H/L).
-- This also overrides WezTerm's default Cmd+N (New Window) and macOS Cmd+H (Hide).
local act = wezterm.action
config.keys = {
  {
    key = "h",
    mods = "CMD",
    action = act.Multiple({
      act.SendKey({ key = " ", mods = "CTRL" }), -- herdr prefix (Ctrl+Space)
      act.SendKey({ key = "h", mods = "SHIFT" }), -- previous_workspace (prefix+shift+h)
    }),
  },
  {
    key = "n",
    mods = "CMD",
    action = act.Multiple({
      act.SendKey({ key = " ", mods = "CTRL" }),
      act.SendKey({ key = "l", mods = "SHIFT" }), -- next_workspace (prefix+shift+l)
    }),
  },
}

return config