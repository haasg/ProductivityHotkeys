# ProductivityHotkeys

My personal hotkey concoction for having to take hands off the keyboard less.

Two things live here:

1. **Cursor hotkeys** - Modifier + JKIL to move the cursor (plus U/O for
   home/end), the same way on Windows (`Alt`) and Mac (`Cmd`).
2. **Keyboard-driven dev environment** - a [herdr](https://herdr.dev/) + Neovim
   workflow for supervising Claude Code agents in parallel git worktrees. Same
   config on both machines. Architecture, key cheatsheet, and troubleshooting:
   **[WORKFLOW.md](WORKFLOW.md)**.

## Repo layout

| Path | What it is |
|------|------------|
| `WORKFLOW.md` | the dev-workflow doc: architecture, keys, daily loop |
| `dotfiles/` | Mac source of truth (nix + home-manager) - **also the shared config tree** |
| `dotfiles/home/.config/nvim/` | Neovim config, shared by both machines |
| `dotfiles/home/.config/wezterm/wezterm.lua` | WezTerm config, shared (OS branch inside) |
| `dotfiles/home/.config/herdr/config.toml` | herdr config (Mac) |
| `dotfiles/home/AGENTS.md` | global agent instructions (Claude + Codex), shared |
| `PC/setup.ps1` | one-script bootstrap for a new Windows machine |
| `PC/link-configs.ps1` | declares every Windows dotfile symlink (the nix `mkOutOfStoreSymlink` analog) |
| `PC/herdr-config.toml` | herdr config (Windows) - mirrors the Mac one, PowerShell command block |
| `PC/powershell-profile.ps1` | pwsh profile: starship + aliases (the zsh mirror) |
| `PC/myHotkeys.ahk` | AutoHotkey script - Alt+JKIL cursor movement on Windows |
| `Mac/init.lua` | Hammerspoon config - Cmd/Alt+JKIL cursor movement on macOS |
| `statusline.py` | Claude Code statusLine - context tokens, model, git branch (cross-platform) |

## Windows setup

1. **Everything terminal/editor/agent** - run `PC/setup.ps1` from an **elevated**
   PowerShell (symlinks need it, or turn on Developer Mode first). It installs
   scoop + the CLI tools + the Nerd Font, installs **herdr** and **Claude Code**,
   symlinks every shared config into place (`link-configs.ps1`), writes the
   statusLine, and bootstraps Neovim plugins.

2. **Hotkeys** - install [AutoHotkey](https://www.autohotkey.com/) and run
   `PC/myHotkeys.ahk`. It's **AHK v1 syntax** - pick v1.1 if a fresh install
   prompts. To run at startup, drop a shortcut to it in `shell:startup`.

3. **Go** - restart the terminal, then run `herdr`. See [WORKFLOW.md](WORKFLOW.md).

> herdr on Windows is officially **preview/beta**; the Mac build is the reference.

## Mac setup

The Mac is managed declaratively with nix (nix-darwin + home-manager) under
`dotfiles/`.

1. **Everything** - `dotfiles/rebuild.sh` (symlinks the repo to `~/.dotfiles` and
   runs `darwin-rebuild switch`). This installs the CLI tools, starship, WezTerm,
   herdr, and Claude Code, and symlinks the shared configs (`wezterm`, `nvim`,
   `herdr`, `AGENTS.md`, `settings.json`).

2. **Hotkeys** - `brew install --cask hammerspoon`, copy `Mac/init.lua` to
   `~/.hammerspoon/init.lua`, reload (Hammerspoon isn't managed by nix).

3. **Go** - run `herdr`.

## CLI tools

Installed by `setup.ps1` (Windows) / nix + Homebrew (Mac). Kept in sync across both.

| Tool | Why |
|------|-----|
| `herdr` | agent multiplexer - the day-to-day driver (workspaces = worktrees) |
| `neovim` | editor (minimal hand-rolled config: snacks, oil, neogit, gitsigns, which-key) |
| `wezterm` | terminal herdr runs inside |
| `claude` (Claude Code) | the agent being supervised |
| `lazygit` | standalone git TUI (Neovim's git review is Neogit/Diffview) |
| `starship` | shell prompt |
| `ripgrep` / `fd` / `fzf` | fast grep / find / fuzzy finder (Neovim pickers use them) |
| `jq` | JSON on the command line |
| `gh` | GitHub CLI - PRs from the terminal |
| `Hack Nerd Font` | the font everything renders in |
| `pwsh` | PowerShell 7, WezTerm's default shell on Windows |
