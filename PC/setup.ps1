# Bootstrap a new Windows machine for the keyboard-driven, herdr-based agent workflow.
# Run from anywhere:  .\PC\setup.ps1   (safe to re-run; existing configs are backed up)
# This mirrors the Mac side (dotfiles/ via nix) as closely as Windows allows.
# See README.md (Windows setup) and WORKFLOW.md for what it builds.

$ErrorActionPreference = "Stop"
$here = $PSScriptRoot

# --- 1. scoop + packages (the Windows stand-in for nix home.packages) --------
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
}
scoop bucket add main
scoop bucket add extras
scoop bucket add nerd-fonts

# Core, matched to the Mac: same CLI + prompt + terminal + font.
#   neovim ripgrep fd fzf jq lazygit  -> home.packages
#   starship                          -> programs.starship
#   Hack-NF                           -> nerd-fonts.hack (the font everything renders in)
#   wezterm                           -> homebrew cask "wezterm"
#   pwsh                              -> WezTerm's default shell
#   gh                                -> PRs from the terminal (PC extra)
scoop install neovim ripgrep fd fzf jq lazygit starship gh pwsh wezterm Hack-NF

# Optional, only if a project needs it (Mac had corretto@11):
#   scoop bucket add java; scoop install corretto11-jdk

# --- 2. herdr: the multiplexer (Windows is preview/beta) ---------------------
# Mac installs it via `brew install herdr`; Windows uses the official installer.
if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
    powershell -ExecutionPolicy Bypass -c "irm https://herdr.dev/install.ps1 | iex"
}

# --- 2b. treehouse: the git-worktree pool herdr's Shift+C leases from ---------
# Mac gets it from the flake input (dotfiles/flake.nix); Windows uses the installer.
if (-not (Get-Command treehouse -ErrorAction SilentlyContinue)) {
    powershell -ExecutionPolicy Bypass -c "irm https://kunchenguid.github.io/treehouse/install.ps1 | iex"
}

# --- 3. Claude Code ----------------------------------------------------------
# Mac installs the "claude-code" cask. On Windows use the official installer
# (see claude.com/claude-code if this command ever changes).
if (-not (Get-Command claude -ErrorAction SilentlyContinue)) {
    powershell -ExecutionPolicy Bypass -c "irm https://claude.ai/install.ps1 | iex"
}

# --- 4. link every shared config into place (the mkOutOfStoreSymlink analog) --
# wezterm, nvim, herdr, ~/.claude/CLAUDE.md, ~/.codex/AGENTS.md, the pwsh profile.
& "$here\link-configs.ps1"

# --- 5. Claude Code statusLine (PC-specific; settings.json is NOT symlinked) --
# The Mac settings.json hardcodes a /Users path + python3, so Windows writes its own.
$claudeDir = "$env:USERPROFILE\.claude"
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Force $claudeDir | Out-Null }
Copy-Item "$here\..\statusline.py" "$claudeDir\statusline.py" -Force
$settingsPath = "$claudeDir\settings.json"
$settings = if (Test-Path $settingsPath) { Get-Content $settingsPath -Raw | ConvertFrom-Json } else { [pscustomobject]@{} }
$statusLine = [pscustomobject]@{ type = "command"; command = "python `"$claudeDir\statusline.py`"" }
$settings | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine -Force
$settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding utf8

# --- 6. bootstrap nvim plugins ----------------------------------------------
# The shared config bootstraps lazy.nvim on first launch, then installs plugins.
# (No treesitter/mingw/mason step anymore - the config is intentionally minimal.)
nvim --headless "+Lazy! sync" +qa

Write-Host ""
Write-Host "Done. Next steps:"
Write-Host "  1. Restart the terminal (pwsh profile + PATH), then run:  herdr"
Write-Host "  2. Install AutoHotkey v1.1 and run PC\myHotkeys.ahk (drop a shortcut in shell:startup)."
Write-Host "  3. Open nvim once and let lazy.nvim finish installing plugins."
