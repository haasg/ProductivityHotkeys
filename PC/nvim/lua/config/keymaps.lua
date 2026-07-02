-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Windows-style editing, designed to pair with the global AutoHotkey Alt-layer
-- (PC/myHotkeys.ahk). Alt+j/k/i/l arrive here as real arrow keys, Alt+Shift+...
-- as Shift+arrows, and Alt+c / Alt+v as Ctrl+C / Ctrl+V — so with these maps
-- Neovim edits like any Windows app, while normal mode stays fully available.

-- Shift+arrows start a selection (Select mode); plain arrows end it.
vim.opt.keymodel = { "startsel", "stopsel" }

local map = vim.keymap.set

-- Copy / cut / paste. LazyVim sets clipboard=unnamedplus, so yanks and deletes
-- already go through the system clipboard — these just put them on the
-- Windows keys. ("x" = Visual mode, "s" = the Select mode Shift+arrows use;
-- <C-o> runs one Visual-mode command from Select mode.)
map("x", "<C-c>", "y", { desc = "Copy selection" })
map("s", "<C-c>", "<C-o>y", { desc = "Copy selection" })
map("x", "<C-x>", "d", { desc = "Cut selection" })
map("s", "<C-x>", "<C-o>d", { desc = "Cut selection" })
map("x", "<C-v>", "P", { desc = "Paste over selection" })
map("s", "<C-v>", "<C-o>P", { desc = "Paste over selection" })
map("i", "<C-v>", "<C-r><C-o>+", { desc = "Paste" })
map("n", "<C-v>", '"+P', { desc = "Paste (visual block moved to Ctrl+Q)" })

-- Undo / redo without having to know about normal mode
map("i", "<C-z>", "<C-o>u", { desc = "Undo" })
map("n", "<C-z>", "u", { desc = "Undo" })
map("i", "<C-y>", "<C-o><C-r>", { desc = "Redo" })
map("n", "<C-y>", "<C-r>", { desc = "Redo" })
