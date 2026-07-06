-- Ctrl-j/k/i/l moves across vim splits and WezTerm panes as one grid,
-- arrow-style like the AHK Alt-layer: j=left, k=down, i=up, l=right.
-- The WezTerm half of this lives in wezterm.lua (nav_key + IS_NVIM user var).
-- Note: <C-i> needs the kitty keyboard protocol (enable_kitty_keyboard in
-- wezterm.lua) to be distinguishable from Tab; without it, Tab in normal mode
-- would also trigger the up-move.
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    { "<C-j>", function() require("smart-splits").move_cursor_left() end },
    { "<C-k>", function() require("smart-splits").move_cursor_down() end },
    { "<C-i>", function() require("smart-splits").move_cursor_up() end },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end },
  },
}
