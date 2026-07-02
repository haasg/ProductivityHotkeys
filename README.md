# ProductivityHotkeys

My personal hotkey concoction for having to take hands off the keyboard less.

Two things live here:

1. **Cursor hotkeys** — Modifier + JKIL to move the cursor (plus U/O for
   home/end), the same way on Windows and Mac.
2. **Keyboard-driven dev environment** — WezTerm + LazyVim + lazygit workflow
   for supervising Claude Code agents in parallel worktrees. Architecture, key
   cheatsheet, and troubleshooting: **[WORKFLOW.md](WORKFLOW.md)**.

## Repo layout

| File | What it is |
|------|------------|
| `WORKFLOW.md` | the dev-workflow doc: architecture, keys, daily loop |
| `PC/setup.ps1` | one-script bootstrap for a new Windows machine |
| `PC/myHotkeys.ahk` | AutoHotkey script — JKIL cursor movement on Windows |
| `PC/wezterm.lua` | WezTerm config (multiplexer keys + appearance) |
| `PC/nvim/` | LazyVim overlay (rust, diffview, smart-splits, PATH fixes) |
| `PC/lazygit-config.yml` | lazygit paging through delta |
| `PC/powershell-profile.ps1` | pwsh profile: zoxide + `lg` alias |
| `PC/terminal-shortcuts` | Git Bash aliases (`~/.bashrc`) |
| `Mac/init.lua` | Hammerspoon config — JKIL cursor movement on macOS |
| `Mac/terminal-shortcuts` | zsh aliases (`~/.zshrc`) |
| `notify.sh` | terminal-notifier hook so Codex CLI pings when a task finishes |

## Windows setup

1. **Everything terminal/editor/git** — run `PC/setup.ps1`. It installs scoop +
   all tools + the Nerd Font, wires delta/difftastic into git, installs LazyVim,
   overlays the configs from this repo, and bootstraps plugins. Then open nvim,
   let mason/treesitter finish, and confirm `:checkhealth` is clean.

2. **Hotkeys** — install [AutoHotkey](https://www.autohotkey.com/) and run
   `PC/myHotkeys.ahk`. Note: the script is **AHK v1 syntax** — on a fresh
   install pick v1.1 when it prompts. To run at startup, drop a shortcut to it
   in `shell:startup`.

3. **Aliases** — append `PC/terminal-shortcuts` to `~/.bashrc` (Git Bash).

## Mac setup

1. **Hotkeys** — `brew install --cask hammerspoon`, then copy `Mac/init.lua` to
   `~/.hammerspoon/init.lua` and reload (⌃⌘⌥R once loaded).

2. **Aliases** — append `Mac/terminal-shortcuts` to `~/.zshrc`.

3. **Notifications** — `brew install terminal-notifier`, then point Codex CLI's
   notify hook at `notify.sh`.

4. **Terminal** — iTerm2 setup: https://catalins.tech/improve-mac-terminal/

5. **Dev workflow** — not ported yet; the plan is **tmux** as the multiplexer on
   Mac (WezTerm-as-multiplexer is a Windows-only compromise). See the Mac plan
   in [WORKFLOW.md](WORKFLOW.md#mac-plan).

## CLI tools (installed by setup.ps1)

| Tool | Why |
|------|-----|
| `neovim` + LazyVim | editor |
| `lazygit` | git TUI; main day-to-day git interface |
| `delta` | diff pager for git + lazygit (side-by-side, word-level) |
| `difftastic` | structural diffs; `git dft` for post-rustfmt review |
| `ripgrep` (`rg`) | fast grep (LazyVim pickers need it) |
| `fd` | fast find (LazyVim pickers need it) |
| `fzf` | fuzzy finder |
| `zoxide` | smarter `cd` (`z <dir>`) |
| `gh` | GitHub CLI — PRs from the terminal |
| `mingw` | gcc for treesitter parser compilation (#1 setup tripwire) |
| `pwsh` | PowerShell 7, WezTerm's default shell |
| `JetBrainsMono-NF` | Nerd Font for LazyVim UI glyphs |
