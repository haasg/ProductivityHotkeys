-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Strawberry Perl's bundled gcc (13.2) shadows scoop's mingw in PATH and its ld
-- can't write the \\?\ extended-length paths tree-sitter uses, which breaks
-- parser compilation. Prefer scoop's toolchain inside nvim only.
if vim.fn.has("win32") == 1 then
  local mingw = vim.fn.expand("~/scoop/apps/mingw/current/bin")
  if vim.fn.isdirectory(mingw) == 1 then
    vim.env.PATH = mingw .. ";" .. vim.env.PATH
  end
end

-- Mason only prepends its bin dir to PATH once the plugin loads (it's lazy),
-- so tools it installs (tree-sitter CLI) are otherwise invisible at startup.
vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin" .. (vim.fn.has("win32") == 1 and ";" or ":") .. vim.env.PATH
