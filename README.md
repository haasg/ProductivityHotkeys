# ProductivityHotkeys

My personal hotkey concoction for having to take hands off the keyboard less.

General idea is Modifier + JKIL to move the cursor (plus U/O for home/end), the same way on Windows and Mac. This repo holds everything needed to reproduce the setup on a new machine.

## Repo layout

| File | What it is |
|------|------------|
| `PC/myHotkeys.ahk` | AutoHotkey script — JKIL cursor movement on Windows |
| `PC/setup.ps1` | Installs scoop + CLI tools on a new Windows machine |
| `PC/terminal-shortcuts` | Git Bash aliases (`~/.bashrc`) |
| `Mac/init.lua` | Hammerspoon config — JKIL cursor movement on macOS |
| `Mac/terminal-shortcuts` | zsh aliases (`~/.zshrc`) |
| `notify.sh` | terminal-notifier hook so Codex CLI pings when a task finishes |

## Windows setup

1. **CLI tools** — run `PC/setup.ps1` (installs scoop if needed, then the tools):

   ```powershell
   scoop bucket add main
   scoop bucket add extras
   scoop install neovim lazygit delta difftastic ripgrep fd fzf zoxide gh mingw
   ```

2. **Hotkeys** — install [AutoHotkey](https://www.autohotkey.com/) and run `PC/myHotkeys.ahk`. Note: the script is **AHK v1 syntax** — on a fresh AHK v2 install, pick v1.1 when it prompts (or install v1.1 directly). To run at startup, drop a shortcut to it in `shell:startup`.

3. **Aliases** — append `PC/terminal-shortcuts` to `~/.bashrc` (Git Bash comes with the `mingw`/git install).

## Mac setup

1. **Hotkeys** — `brew install --cask hammerspoon`, then copy `Mac/init.lua` to `~/.hammerspoon/init.lua` and reload (⌃⌘⌥R once loaded).

2. **Aliases** — append `Mac/terminal-shortcuts` to `~/.zshrc`.

3. **Notifications** — `brew install terminal-notifier`, then point Codex CLI's notify hook at `notify.sh`.

4. **Terminal** — iTerm2 setup: https://catalins.tech/improve-mac-terminal/

## CLI tools

| Tool | Why |
|------|-----|
| `neovim` | editor |
| `lazygit` | git TUI |
| `delta` / `difftastic` | better diffs |
| `ripgrep` (`rg`) | fast grep |
| `fd` | fast find |
| `fzf` | fuzzy finder |
| `zoxide` | smarter `cd` |
| `gh` | GitHub CLI |
| `mingw` | gcc toolchain (nvim plugin builds, etc.) |
