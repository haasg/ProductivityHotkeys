# Keyboard-Driven Agent Dev Workflow

Zero-mouse setup for supervising Claude Code agents in parallel git worktrees.
The human's job is code review, so fast diff inspection and git ergonomics are
the priority. Windows is primary; macOS is secondary (see [Mac plan](#mac-plan)).

To reproduce on a new Windows machine: run `PC/setup.ps1`, then read this file.

## Architecture

Four keybinding layers, no collisions:

| Layer | Prefix | Role |
|---|---|---|
| AutoHotkey (Windows-global) | `Alt` | `Alt+j/k/i/l` = arrows, `Alt+u/o` = Home/End, `Alt+h/n` = PgUp/PgDn — in every app, including Neovim |
| WezTerm (multiplexer) | `Ctrl-a` (leader) | Workspaces, tabs, splits |
| Neovim (LazyVim) | `Space` | Editing, LSP, git review |
| Universal navigation | `Ctrl-h/j/k/l` | Move across vim splits AND WezTerm panes as one grid |

The AHK `Ctrl+j/k/l/i` variants (word-jump / 6-line hop) are disabled inside
WezTerm (`#IfWinNotActive` guard in myHotkeys.ahk) so they can't shadow the
universal navigation layer. Inside the terminal, use real `Ctrl+←/→` for
word-jumps instead.

Core pattern: **one git worktree = one WezTerm workspace = one agent.**
Tab 1 = Neovim, Tab 2 = Claude Code, Tab 3 = shell/lazygit.

On Windows, WezTerm's built-in multiplexer stands in for tmux (which doesn't run
natively there). WSL2 was rejected: the Rust/game toolchain needs native Windows
(GPU, Win32, native builds).

## Key cheatsheet

**WezTerm (leader = `Ctrl-a`, then...)**

| Key | Action |
|---|---|
| `s` | fuzzy-pick workspace |
| `w` | new named workspace |
| `c` / `n` / `p` / `1-8` | new tab / next / prev / jump to tab |
| `\` / `-` | split right / split down (`\|` also works for split right) |
| `x` / `z` | close pane / zoom pane |

`Ctrl-h/j/k/l` moves between panes — and between vim splits when the pane is
running nvim (smart-splits.nvim sets an `IS_NVIM` user var; wezterm.lua checks it).

**Neovim review keys (leader = `Space`)**

| Key | Action |
|---|---|
| `<space><space>` | find files |
| `<space>/` | live grep |
| `gd` | go to definition |
| `<space>gd` | diffview: working tree changes (`Tab`/`S-Tab` cycle files, `]c`/`[c` jump hunks) |
| `<space>gD` | diffview: whole branch vs main |
| `<space>gh` | file history for current file |
| `<space>gg` | lazygit floating window |

**Neovim editing, Windows-style (no vim-golf required)**

The AHK Alt-layer plus `config/keymaps.lua` means Neovim edits like a normal
Windows app. Live in insert mode; pop to normal mode (`Esc`) only for the
Space menu.

| Key | Action |
|---|---|
| `i` / `Esc` | start / stop typing (insert ↔ normal mode) |
| `Alt+j/k/i/l` | move cursor (works in any mode — they're real arrows) |
| `Alt+Shift+j/k/i/l` | select text, Windows-style |
| `Alt+c` / `Alt+v` / `Ctrl+X` | copy / paste / cut (system clipboard) |
| `Ctrl+S` | save, even from insert mode |
| `Ctrl+Z` / `Ctrl+Y` | undo / redo, even from insert mode |
| `Ctrl+←/→` | jump by word |

Caveats: `Alt+a` (select-all) is dead in the terminal — `Ctrl+A` is the WezTerm
leader. In a shell/Claude pane, `Alt+c` is `Ctrl+C` = interrupt, not copy.

**Shell / git**

- `z <dir>` — zoxide frecency jump; `lg` — lazygit
- `git dft` — difftastic structural diff (post-rustfmt / refactor review)
- delta is the pager for `git diff`/`log`/lazygit (side-by-side, word-level)

## Daily loop

1. `Ctrl-a s` → pick workspace (or `Ctrl-a w` → create one per worktree/agent)
2. Tab 1: `nvim` — navigate, read, edit
3. Tab 2: Claude Code running against that worktree
   (or side-by-side: `Ctrl-a \` splits, run `claude` in the new pane,
   `Ctrl-h`/`Ctrl-l` hop between vim and Claude, `Ctrl-a z` zooms one pane)
4. Review: `<space>gD` for the branch diff tree, or `<space>gg` to stage
   hunk-by-hunk and commit; `git dft` when formatting churn drowns the diff
5. `gh pr create` when the branch is ready

## What lives where

| Repo file | Deploys to | What it does |
|---|---|---|
| `PC/wezterm.lua` | `~/.wezterm.lua` | terminal + multiplexer keys + appearance |
| `PC/nvim/lazyvim.json` | `%LOCALAPPDATA%\nvim\` | enables the `lang.rust` LazyVim extra |
| `PC/nvim/lua/config/options.lua` | `%LOCALAPPDATA%\nvim\lua\config\` | PATH fixes (see troubleshooting) |
| `PC/nvim/lua/config/keymaps.lua` | `%LOCALAPPDATA%\nvim\lua\config\` | Windows-style select/copy/paste/undo (pairs with AHK Alt-layer) |
| `PC/myHotkeys.ahk` | run at startup with AutoHotkey v1 | global Alt-layer arrows; Ctrl-variants disabled inside WezTerm |
| `PC/nvim/lua/plugins/rust.lua` | `...\lua\plugins\` | rust-analyzer: clippy on check, not allFeatures |
| `PC/nvim/lua/plugins/diffview.lua` | `...\lua\plugins\` | branch review keymaps |
| `PC/nvim/lua/plugins/smart-splits.lua` | `...\lua\plugins\` | nvim half of unified Ctrl-h/j/k/l |
| `PC/lazygit-config.yml` | `%LOCALAPPDATA%\lazygit\config.yml` | delta as lazygit's pager |
| `PC/powershell-profile.ps1` | `~\Documents\PowerShell\Microsoft.PowerShell_profile.ps1` | zoxide init + `lg` alias |

## Troubleshooting (learned the hard way)

- **Treesitter parsers fail to compile with `ld.exe: cannot open output file \\?\C:\... Invalid argument`**:
  another gcc is shadowing scoop's mingw in PATH (on this machine: Strawberry
  Perl's bundled gcc 13.2, which can't write `\\?\` extended-length paths).
  `PC/nvim/lua/config/options.lua` fixes it by prepending scoop's mingw to PATH
  inside nvim only. If it recurs, check `gcc --version` — it should say
  MinGW-Builds 16.x, not Strawberry.
- **checkhealth says `tree-sitter (CLI) is not installed`** even though mason
  installed it: mason only adds its bin dir to PATH once the plugin loads.
  options.lua prepends `nvim-data/mason/bin` at startup.
- **Headless `nvim +"Lazy! sync"` reports "Package is already installing"** on
  first run: benign race between LazyVim's auto-install and the sync; run it
  again. Mason installs (codelldb) abort if nvim exits mid-download — just
  reopen nvim and let them finish.
- **Window can't be dragged**: `window_decorations` must include
  `INTEGRATED_BUTTONS` (the tab bar is the drag handle — which is also why
  `hide_tab_bar_if_only_one_tab = false`).
- **Boxes/missing glyphs in nvim UI**: WezTerm font must be a Nerd Font
  (`JetBrainsMono Nerd Font`, installed via scoop's nerd-fonts bucket).

## Deferred / next steps

- **Worktree-spawner script**: `git worktree add` → named workspace → spawn
  Claude Code pane, plus teardown. Build after a few days of real use, once the
  preferred spawn layout is known.
- <a name="mac-plan"></a>**Mac plan**: use **tmux** as the multiplexer instead of
  WezTerm workspaces (tmux is first-class on macOS; WezTerm-as-multiplexer was a
  Windows-only compromise — reevaluate later). Keep the same three-layer
  contract: `Ctrl-a` = tmux prefix, `Space` = nvim leader, `Ctrl-h/j/k/l` =
  universal pane nav (vim-tmux-navigator instead of the wezterm callback).
  Everything in `PC/nvim/` ports as-is except the Windows PATH fixes in
  options.lua; install tools with Homebrew.
- Keybinding contract to preserve: any future additions must not collide with
  the three layers above.
