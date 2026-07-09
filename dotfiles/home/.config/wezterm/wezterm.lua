-- WezTerm config, shared by Mac and Windows (same file symlinked on both).
-- Reload live with the config-reload key or by saving (auto-reloads on save).
--
-- In this setup WezTerm is JUST a terminal. herdr is the multiplexer: it owns
-- workspaces (= git worktrees), agent cycling, tabs, splits, and copy-mode. See
-- WORKFLOW.md. That is why there are almost no keys here - herdr's prefix
-- (Ctrl+Space) does the work, and nvim's leader is Space.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Appearance (shared) -------------------------------------------------------
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.hide_tab_bar_if_only_one_tab = true
config.window_background_opacity = 0.9

if is_windows then
  -- Windows tuning: bigger DPI density wants a smaller point size, and the
  -- DirectWrite default renders unevenly - FreeType Light/HorizontalLcd is
  -- crisper. RESIZE alone leaves no drag handle on Windows, so keep the
  -- integrated buttons (that title strip is how you move the window).
  config.font_size = 11.0
  config.freetype_load_target = "Light"
  config.freetype_render_target = "HorizontalLcd"
  config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
  config.default_prog = { "pwsh.exe", "-NoLogo" }
  config.default_cwd = "C:/repo"
else
  -- macOS gives a true frosted-glass blur behind the translucent window.
  config.font_size = 15.0
  config.macos_window_background_blur = 50
  config.window_decorations = "RESIZE"
end

-- Keys ----------------------------------------------------------------------
-- Only macOS needs keys here. macOS intercepts Cmd before the terminal can
-- forward it, and the Cmd/super modifier can't travel through a terminal input
-- stream anyway, so translate Cmd+H / Cmd+N into herdr's prev/next-workspace
-- prefix sequence (Ctrl+Space, then Shift+H / Shift+L). This also overrides
-- WezTerm's default Cmd+N (New Window) and macOS Cmd+H (Hide).
--
-- On Windows there is no Cmd: use herdr's bindings directly (Ctrl+Space then
-- Shift+H / Shift+L for prev/next workspace). Nothing to translate, so no keys.
if not is_windows then
  config.keys = {
    {
      key = "h",
      mods = "CMD",
      action = act.Multiple({
        act.SendKey({ key = " ", mods = "CTRL" }),  -- herdr prefix (Ctrl+Space)
        act.SendKey({ key = "h", mods = "SHIFT" }), -- previous_workspace
      }),
    },
    {
      key = "n",
      mods = "CMD",
      action = act.Multiple({
        act.SendKey({ key = " ", mods = "CTRL" }),
        act.SendKey({ key = "l", mods = "SHIFT" }), -- next_workspace
      }),
    },
  }
end

return config
