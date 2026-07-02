-- Ctrl-h/j/k/l moves across vim splits and WezTerm panes as one grid.
-- The WezTerm half of this lives in wezterm.lua (nav_key + IS_NVIM user var).
return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  keys = {
    { "<C-h>", function() require("smart-splits").move_cursor_left() end },
    { "<C-j>", function() require("smart-splits").move_cursor_down() end },
    { "<C-k>", function() require("smart-splits").move_cursor_up() end },
    { "<C-l>", function() require("smart-splits").move_cursor_right() end },
  },
}
