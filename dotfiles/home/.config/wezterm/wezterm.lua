-- WezTerm config, shared by Mac and Windows (same file symlinked on both).
-- Reload live with the config-reload key or by saving (auto-reloads on save).
--
-- In this setup WezTerm is JUST a terminal. herdr is the multiplexer: it owns
-- workspaces (= git worktrees), agent cycling, tabs, splits, and copy-mode. See
-- WORKFLOW.md. That is why there are almost no keys here - herdr's prefix
-- (Ctrl+Space) does the work, and nvim's leader is Space.
--
-- CRITICAL: never define `config.leader` here, and never let a `~/.wezterm.lua`
-- exist. WezTerm reads ~/.wezterm.lua FIRST and this file only as a fallback, and
-- a WezTerm leader on Ctrl+Space swallows herdr's prefix before herdr sees it.
-- That exact pair silently disabled every herdr key. `wezterm show-keys` must
-- print no `Leader:` line.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- Appearance (shared) -------------------------------------------------------
config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("Hack Nerd Font")
config.window_background_opacity = 0.9

if is_windows then
  -- Windows tuning: bigger DPI density wants a smaller point size, and the
  -- DirectWrite default renders unevenly - FreeType Light/HorizontalLcd is
  -- crisper. RESIZE alone leaves no drag handle on Windows, so keep the
  -- integrated buttons. The buttons render inside the tab bar, so the tab bar
  -- must stay visible even with one tab (herdr owns tabs, so there is always
  -- exactly one) - otherwise the drag strip vanishes and the window can only
  -- be resized, never moved.
  config.hide_tab_bar_if_only_one_tab = false
  config.font_size = 11.0
  config.freetype_load_target = "Light"
  config.freetype_render_target = "HorizontalLcd"
  config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
  config.default_prog = { "pwsh.exe", "-NoLogo" }
  config.default_cwd = "C:/repo"
else
  -- macOS gives a true frosted-glass blur behind the translucent window.
  -- No tab bar needed here: the window is dragged by its RESIZE frame edge.
  config.hide_tab_bar_if_only_one_tab = true
  config.font_size = 15.0
  config.macos_window_background_blur = 50
  config.window_decorations = "RESIZE"
end

-- Keys ----------------------------------------------------------------------
-- The only keys defined here are chords herdr cannot bind for itself. Each one
-- is caught before WezTerm encodes it and replayed as herdr's prefix sequence
-- (Ctrl+Space, then a key), so herdr receives an ordinary binding.
local function herdr_prefix(key, mods)
  return act.Multiple({
    act.SendKey({ key = " ", mods = "CTRL" }), -- herdr prefix (Ctrl+Space)
    act.SendKey(mods and { key = key, mods = mods } or { key = key }),
  })
end

-- Alt+[ / Alt+] - previous / next tab in the focused herdr workspace.
-- herdr can't bind Alt+[ directly: a terminal encodes Alt+x as ESC x, so the
-- chord would arrive as ESC [ - a bare CSI introducer - and herdr's input
-- parser would swallow it as the start of an escape sequence. Catching it here
-- means it is never encoded that way. (These used to switch WezTerm's own tabs;
-- herdr owns tabs now, and WezTerm runs as a single un-tabbed window.)
config.keys = {
  { key = "[", mods = "ALT", action = herdr_prefix("[") }, -- previous_tab
  { key = "]", mods = "ALT", action = herdr_prefix("]") }, -- next_tab
}

-- Cmd+H / Cmd+N - previous / next herdr workspace. macOS only: macOS intercepts
-- Cmd before the terminal can forward it, and the Cmd/super modifier can't
-- travel through a terminal input stream anyway. This also overrides WezTerm's
-- default Cmd+N (New Window) and macOS Cmd+H (Hide). On Windows there is no Cmd:
-- use herdr's bindings directly (Ctrl+Space then Shift+H / Shift+L).
if not is_windows then
  table.insert(config.keys, { key = "h", mods = "CMD", action = herdr_prefix("h", "SHIFT") })
  table.insert(config.keys, { key = "n", mods = "CMD", action = herdr_prefix("l", "SHIFT") })
end

return config
