-- WezTerm configuration. Reload live with Ctrl+Shift+R (or it auto-reloads on save).
-- Full reference: https://wezterm.org/config/lua/general.html
--
-- Keybinding layers (must not collide):
--   Ctrl-Space (leader) = multiplexer: workspaces, tabs, splits
--   Space            = Neovim leader (inside nvim)
--   Ctrl-j/k/i/l     = universal pane movement (vim splits + wezterm panes),
--                      arrow-style like the AHK Alt-layer: j=left k=down i=up l=right

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Appearance ──────────────────────────────────────────────
-- Browse built-in schemes: https://wezterm.org/colorschemes/index.html
config.color_scheme = 'Tokyo Night'

-- To try a font: change this one string, save, Ctrl+Shift+R. Keep ONE family here
-- (a mixed fallback list is what makes text sit unevenly). Candidates to rotate:
--   'Cascadia Code'  'JetBrains Mono'  'Consolas'          (already installed)
--   'JetBrainsMono Nerd Font' (installed; has LazyVim UI glyphs)
--   'Iosevka'  'Hack'  'Fira Code'  'IBM Plex Mono'  'Maple Mono'  (install first)
config.font = wezterm.font 'Cascadia Code'
config.font_size = 11.0
config.line_height = 1.0

-- Crisper, more consistent vertical rendering than the default DirectWrite path.
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd'

-- ── Window ──────────────────────────────────────────────────
config.window_background_opacity = 0.95   -- 1.0 = opaque
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'  -- draggable tab bar + resize borders
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.initial_cols = 120
config.initial_rows = 32

-- ── Tab bar ─────────────────────────────────────────────────
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false  -- keep visible: it's the drag handle
config.tab_bar_at_bottom = false

-- ── Cursor ──────────────────────────────────────────────────
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500

-- ── Scrollback ──────────────────────────────────────────────
config.scrollback_lines = 10000

-- ── Shell ───────────────────────────────────────────────────
config.default_prog = { 'pwsh.exe', '-NoLogo' }
-- Where fresh windows start. Note this is only a fallback: on Windows, wezterm
-- reads the live cwd of a pane's shell process, so anything spawned relative to
-- an existing pane (SpawnTab, splits) inherits that pane's directory instead.
-- The leader-c tab binding below pins its cwd explicitly for this reason.
config.default_cwd = 'C:/repo'

-- ── Multiplexer keys (leader = Ctrl-Space) ──────────────────
-- Costs: nvim never sees Ctrl-Space (its manual completion trigger; auto-popup
-- is unaffected) and PSReadLine loses MenuComplete. Ctrl-a passes through again.
config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1500 }

config.keys = {
  { key = '[', mods = 'ALT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'ALT', action = act.ActivateTabRelative(1) },
  -- Ctrl variants of the same, so either modifier works. Note: terminals encode
  -- Esc as Ctrl+[, so apps can no longer receive Ctrl+[ as Esc (the Esc key
  -- itself is unaffected), and nvim loses Ctrl+] tag-jump (gd covers it).
  { key = '[', mods = 'CTRL', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  -- Pass Ctrl+= through to nvim (jump back); font zoom keeps Ctrl+Shift+= and Ctrl+-.
  { key = '=', mods = 'CTRL', action = act.DisableDefaultAssignment },
  -- Splits
  -- Split right lives on the \ key. Primary chord is unshifted \ because this
  -- wezterm build is unreliable at matching shifted punctuation after a leader;
  -- both '|' forms are registered too (wezterm's own defaults do the same).
  { key = '\\', mods = 'LEADER', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '|', mods = 'LEADER', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '-', mods = 'LEADER', action = act.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane({ confirm = true }) },
  { key = 'z', mods = 'LEADER', action = act.TogglePaneZoomState },
  -- Rotate panes through the layout slots — with two panes this just swaps them
  -- (e.g. flip claude/nvim left↔right). Same key as tmux's rotate (C-a C-o/o).
  { key = 'o', mods = 'LEADER', action = act.RotatePanes 'Clockwise' },
  -- Tabs
  { key = 'c', mods = 'LEADER', action = act.SpawnCommandInNewTab({ cwd = 'C:/repo' }) },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  -- Workspaces (one per worktree/agent)
  { key = 's', mods = 'LEADER', action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }) },
  { key = 'w', mods = 'LEADER', action = act.PromptInputLine({
      description = 'New workspace name:',
      action = wezterm.action_callback(function(window, pane, line)
        if line and line ~= '' then
          window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
        end
      end),
    }),
  },
}

for i = 1, 8 do
  table.insert(config.keys, { key = tostring(i), mods = 'LEADER', action = act.ActivateTab(i - 1) })
end

-- ── Seamless Ctrl-j/k/i/l across wezterm panes and vim splits ──
-- smart-splits.nvim sets the IS_NVIM user var; when the active pane is nvim,
-- pass the key through so nvim moves between its own splits, else move panes.
-- Directions mirror the AHK Alt-layer: j=left, k=down, i=up, l=right.

-- Lets apps that ask for it (nvim) tell Ctrl+i apart from Tab — required for
-- the Ctrl+i pane-up binding to pass through to vim splits correctly.
config.enable_kitty_keyboard = true
local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == 'true'
end

local function nav_key(key, direction)
  return {
    key = key,
    mods = 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        win:perform_action(act.SendKey({ key = key, mods = 'CTRL' }), pane)
      else
        win:perform_action(act.ActivatePaneDirection(direction), pane)
      end
    end),
  }
end

table.insert(config.keys, nav_key('j', 'Left'))
table.insert(config.keys, nav_key('k', 'Down'))
table.insert(config.keys, nav_key('i', 'Up'))
table.insert(config.keys, nav_key('l', 'Right'))

return config
