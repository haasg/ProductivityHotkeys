# Keyboard-Driven Agent Dev Workflow

Zero-mouse setup for supervising Claude Code agents in parallel git worktrees.
The human's job is code review, so fast diff inspection and git ergonomics are
the priority. The same config drives **both** macOS and Windows; only the OS
cursor layer and a couple of shell details differ.

To reproduce: run `PC/setup.ps1` (Windows) or `dotfiles/rebuild.sh` (Mac), then
read this file.

## Architecture

**[herdr](https://herdr.dev/) is the multiplexer.** It's a Rust agent-multiplexer
built for exactly this: run many coding agents in one terminal, see at a glance
which agent is working / blocked / done, and keep them alive across detach and
restart. One git worktree = one herdr workspace = one agent. herdr replaced the
old WezTerm-as-multiplexer setup (and the never-built tmux plan) - WezTerm is now
just the terminal herdr runs inside.

Three keybinding layers, no collisions:

| Layer | Prefix | Role |
|---|---|---|
| OS cursor layer | `Alt` (Win) / `Cmd` (Mac) | `+j/k/i/l` = arrows, `+u/o` = Home/End, `+h/n` = PgUp/PgDn - in every app, including Neovim. Windows: AutoHotkey (`PC/myHotkeys.ahk`). Mac: Hammerspoon (`Mac/init.lua`). |
| herdr (multiplexer) | `Ctrl-Space` (prefix) | Workspaces (worktrees), agents, tabs, splits, copy-mode |
| Neovim | `Space` (leader) | Editing, git review, pickers |

herdr never lets Neovim see `Ctrl-Space` (it's herdr's prefix), and the OS cursor
layer sends real arrow keys, so nothing shadows the Neovim `Space` leader.

## herdr cheatsheet (prefix = `Ctrl-Space`, then...)

| Key | Action |
|---|---|
| `h` / `j` / `k` / `l` | focus pane left / down / up / right |
| `"` / `%` | split horizontal / vertical |
| `c` / `&` | new tab / close tab |
| `w` | workspace picker (searchable list) |
| `g` | goto |
| `y` | copy-mode (then `v`/`space` select, `y`/`Enter` copy, `q`/`Esc` cancel) |
| `Shift+H` / `Shift+L` | previous / next workspace |
| `Shift+O` / `Shift+X` | open an existing worktree / remove the focused worktree |
| `Shift+C` | **new worktree + start Claude in it** (auto-named branch of the focused repo) |

No prefix needed: `Ctrl+n` / `Ctrl+h` cycle to the next / previous agent directly.

On Mac, `Cmd+H` / `Cmd+N` are wired in `wezterm.lua` to send `Shift+H` / `Shift+L`
prev/next-workspace (macOS eats `Cmd` before the terminal sees it). On Windows
there's no `Cmd`, so use `Ctrl-Space Shift+H/L` directly.

## Neovim cheatsheet (leader = `Space`)

The Neovim config is intentionally minimal and identical on both machines
(`dotfiles/home/.config/nvim/`). `which-key` pops up the full list when you press
`Space`.

| Key | Action |
|---|---|
| `<leader>f` | find files (hidden included - this repo is dotfiles) |
| `<leader>s` | live grep |
| `<leader>b` | buffers |
| `<leader>e` | Oil file browser |
| `<leader>g` | Neogit (stage, commit; opens Diffview for review) |
| `gd` | go to definition |
| `Esc` | save the file |
| `Ctrl+a` | select all |

Git review runs through Neogit + Diffview + gitsigns (inline blame on the current
line). `lazygit` is still installed as a standalone TUI if you prefer it.

## Editing, OS-cursor style (Windows / AutoHotkey)

The AHK Alt-layer makes Neovim (and every app) edit like a normal Windows app -
live in insert mode, pop to normal only for the `Space` menu.

| Key | Action |
|---|---|
| `Alt+j/k/i/l` | move cursor (real arrows, any mode) |
| `Alt+Shift+j/k/i/l` | select text |
| `Alt+u/o` | Home / End &nbsp;&nbsp; `Alt+h/n` | PgUp / PgDn |
| `Alt+c` / `Alt+v` | copy / paste (system clipboard) |

Caveat: in a shell/agent pane, `Alt+c` reaches the app as `Ctrl+C` = interrupt,
not copy. (The Mac Hammerspoon layer is the `Cmd`-based mirror of the same map.)

## Daily loop

1. `herdr` (or reattach - sessions survive restart).
2. `Ctrl-Space Shift+C` - spin up a fresh worktree with Claude already running, or
   `Ctrl-Space w` to jump to an existing workspace.
3. Split the pane (`Ctrl-Space "`), run `nvim` beside Claude; `Ctrl-Space h/l` to
   hop between them.
4. Review the agent's work: `<leader>g` (Neogit) to stage hunk-by-hunk and commit,
   Diffview for the branch diff.
5. `Ctrl+n` / `Ctrl+h` to sweep across the other agents and see who's blocked / done.
6. `gh pr create` when a branch is ready; `Ctrl-Space Shift+X` to tear the worktree down.

## What's shared vs per-OS

| Config | Shared? | Notes |
|---|---|---|
| `dotfiles/home/.config/wezterm/wezterm.lua` | yes | one file; `is_windows` branch for font size / decorations / blur |
| `dotfiles/home/.config/nvim/` | yes | identical on both |
| `dotfiles/home/AGENTS.md` | yes | global agent instructions (Claude `CLAUDE.md` + Codex `AGENTS.md`) |
| herdr `config.toml` | no | Mac `dotfiles/.../herdr/`, Windows `PC/herdr-config.toml` - only the `[[keys.command]]` shell block differs (python3/sh vs PowerShell). Keep in sync. |
| OS cursor layer | no | `PC/myHotkeys.ahk` (AHK) vs `Mac/init.lua` (Hammerspoon) |
| `~/.claude/settings.json` | no | hardcodes an OS path + `python3`/`python` for the statusLine |

## Troubleshooting

- **Windows symlinks need privilege**: `link-configs.ps1` creates symlinks;
  run it from an elevated shell **or** turn on Settings > System > For developers
  > Developer Mode once. Otherwise it warns "access denied" and skips.
- **herdr on Windows is preview/beta** - expect rough edges; the Mac build is the
  reference. Reinstall with `irm https://herdr.dev/install.ps1 | iex`.
- **Neovim clipboard**: the config uses `clipboard=unnamedplus`; recent Neovim on
  Windows has a built-in provider, so yanks reach the system clipboard without
  extra tools.
- **Boxes / missing glyphs**: the WezTerm font must be a Nerd Font
  (`Hack Nerd Font`, installed via scoop's `nerd-fonts` bucket / `nerd-fonts.hack`
  on Mac).

## Deferred / next steps

- **rust-analyzer / LSP in Neovim**: the shared config dropped all LSP/treesitter
  to stay minimal (which is also why Windows no longer needs mingw). Re-add it to
  `dotfiles/home/.config/nvim/lua/plugins/` if wanted - it lands on both machines.
- **Windows-style Neovim editing keymaps** (Ctrl+C/V/X select-mode, J/L buffer
  nav, Ctrl+Z/Y) lived in the old `PC/nvim/lua/config/keymaps.lua`; they're in git
  history if the vim-style keys feel too sparse.
- Keybinding contract to preserve: any future additions must not collide with the
  three layers above.
