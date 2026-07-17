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

**[treehouse](https://github.com/kunchenguid/treehouse) owns the worktrees.**
herdr can create worktrees itself, but a fresh worktree means a cold `cargo
build` every time an agent starts. treehouse instead keeps a **pool** of worktrees
and hands out an idle one, resetting tracked files but leaving gitignored build
output alone - so each tree keeps its own warm `target/`. herdr no longer creates
or destroys worktrees at all; it just renders whatever treehouse leases out.

That split is load-bearing, so all three of herdr's built-in worktree keys are
unbound in `config.toml` (see the comment there). The replacements are two shared
python scripts next to the herdr config, `new-agent.py` and `return-agent.py`.

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
| `[` / `]` | previous / next tab (usually typed as `Alt+[` / `Alt+]`, see below) |
| `w` | workspace picker (searchable list) |
| `g` | goto |
| `y` | copy-mode (then `v`/`space` select, `y`/`Enter` copy, `q`/`Esc` cancel) |
| `Shift+H` / `Shift+L` | previous / next workspace |
| `Shift+C` | **new agent**: lease a warm worktree from the pool, branch it, open Claude (left) + a terminal (right) in it |
| `Shift+X` | **return** the focused worktree to the pool (closes the workspace, keeps the branch) |

No prefix needed: `Ctrl+n` / `Ctrl+h` cycle to the next / previous agent directly.

`Alt+[` / `Alt+]` switch tabs on both OSes. `wezterm.lua` catches the chord and
replays it as `Ctrl-Space [` / `Ctrl-Space ]`; herdr can't bind `Alt+[` itself,
because a terminal encodes `Alt+x` as `ESC x`, so the chord would reach herdr as
`ESC [` - a bare CSI introducer its escape-sequence parser swallows. These keys
used to switch *WezTerm* tabs; herdr owns tabs now.

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
2. `Ctrl-Space Shift+C` - lease a warm worktree with Claude running on the left
   and a terminal on the right, or `Ctrl-Space w` to jump to an existing
   workspace. The tree arrives on a fresh `agent/<timestamp>` branch (pool trees
   are detached by default, and `gh pr create` needs a branch).
3. Run `nvim` in the right-hand terminal to review beside Claude; `Ctrl-Space h/l`
   to hop between the panes.
4. Review the agent's work: `<leader>g` (Neogit) to stage hunk-by-hunk and commit,
   Diffview for the branch diff.
5. `Ctrl+n` / `Ctrl+h` to sweep across the other agents and see who's blocked / done.
6. `gh pr create` when a branch is ready; `Ctrl-Space Shift+X` to hand the worktree
   back to the pool. The branch stays in the repo; the tree keeps its build cache
   for the next agent.

`treehouse status` (from the repo's **main** checkout) shows who holds what.
Pool size is `max_trees`: 6 globally, override per-repo in a `treehouse.toml`.

## What's shared vs per-OS

| Config | Shared? | Notes |
|---|---|---|
| `dotfiles/home/.config/wezterm/wezterm.lua` | yes | one file; `is_windows` branch for font size / decorations / blur |
| `dotfiles/home/.config/nvim/` | yes | identical on both |
| `dotfiles/home/AGENTS.md` | yes | global agent instructions (Claude `CLAUDE.md` + Codex `AGENTS.md`) |
| `dotfiles/home/.config/herdr/{new,return}-agent.py` | yes | the Shift+C / Shift+X logic; only the interpreter differs (`python3` vs `python`) |
| `dotfiles/home/.config/treehouse/config.toml` | yes | treehouse reads `~/.config/treehouse/` on **both** OSes, unlike herdr |
| herdr `config.toml` | no | Mac `dotfiles/.../herdr/`, Windows `PC/herdr-config.toml` - only the `[[keys.command]]` shell block differs (python3/sh vs PowerShell). Keep in sync. Live path differs too: `~/.config/herdr/` on Mac, `%APPDATA%\herdr\` on Windows. |
| OS cursor layer | no | `PC/myHotkeys.ahk` (AHK) vs `Mac/init.lua` (Hammerspoon) |
| `~/.claude/settings.json` | no | hardcodes an OS path + `python3`/`python` for the statusLine |

## Troubleshooting

- **Windows symlinks need privilege**: `link-configs.ps1` creates symlinks;
  run it from an elevated shell **or** turn on Settings > System > For developers
  > Developer Mode once. Otherwise it warns "access denied" and skips.
- **`Ctrl+Space` does nothing / `Ctrl-Space c` opens a *WezTerm* tab**: something
  is eating herdr's prefix before herdr sees it. Almost certainly a stray
  `~/.wezterm.lua`, which WezTerm loads *instead of* `~/.config/wezterm/wezterm.lua`
  (that path is only the fallback). The old pre-herdr config lived there and set
  `Ctrl+Space` as WezTerm's own **leader**, so the prefix never reached herdr.
  Confirm with `wezterm show-keys` - if it prints a `Leader:` line, that's the
  bug. Delete the file; `link-configs.ps1` now moves it aside automatically.
  Anything that consumes `Ctrl+Space` will do this, so check `wezterm show-keys`
  first before suspecting herdr.
- **A keybinding change needs a herdr *restart*, not just a reload.**
  `herdr server reload-config` returns `"status":"applied"` and is still not
  enough: keys are handled client-side (see `herdr-client.log`), so a running
  client keeps the keymap it started with. Quit herdr and relaunch - sessions
  survive it.
- **herdr keybindings do nothing on Windows**: herdr reads
  `%APPDATA%\herdr\config.toml` there, *not* `~/.config/herdr/config.toml` (that's
  the Mac path). Linking the Mac path is a silent no-op - herdr just uses its
  generated stub and none of the `[keys]` bindings load, so `Ctrl+Space`,
  `Ctrl+H`, and `Ctrl+N` all appear dead. Confirm the live file with
  `herdr server reload-config`: it prints `"status":"applied"` and echoes any
  parse error, and the config it reads sits next to `herdr.sock` and the logs.
- **herdr on Windows is preview/beta** - expect rough edges; the Mac build is the
  reference. Reinstall with `irm https://herdr.dev/install.ps1 | iex`.
- **`Ctrl-Space Shift+C/X` does nothing and no error appears**: herdr throws away
  the output of a `type = "shell"` binding, so both scripts append their failures
  to `~/.herdr-agent.log`. Read that first. The usual cause is `treehouse` or
  `python` missing from the PATH *the herdr server started with* - restart herdr
  after installing either.
- **Never re-bind herdr's own worktree keys.** `new_worktree` is bound to
  `prefix+shift+g` **by default**, so deleting the line from `config.toml` is not
  enough to disable it - it must be set to `""`. A stray `Shift+G` mints a
  worktree outside the pool, which then has no warm cache and no lease.
  `remove_worktree` is worse: it's `git worktree remove`, which deletes a pool
  member outright.
- **`treehouse` run from inside a worktree reports an empty pool.** It only
  resolves a pool from the repo's main checkout, and would happily start a
  *second* pool keyed on the worktree. That's why `new-agent.py` asks herdr for
  `worktree list --workspace <id>` -> `source.repo_root` instead of trusting
  `cwd`. (`workspace get` can't answer this: it only carries a `worktree` block
  for workspaces that are themselves worktrees.)
- **treehouse config lives in `~/.config/treehouse/config.toml` on Windows too** -
  not `%APPDATA%`. It's the opposite of herdr, so don't copy that assumption.
- **`[hooks]` only run from the user-level config.** `post_create` / `pre_destroy`
  in a repo's own `treehouse.toml` are silently ignored; everything else
  (`max_trees`, `root`) does override from there.
- **Disk**: treehouse defaults to `max_trees = 16`. Sixteen Rust `target/` dirs is
  a few hundred GB, so the shared config pins it to 6. `treehouse prune` reclaims
  idle merged trees; `treehouse status` shows the pool.
- **A stuck lease is never handed out again** and survives `prune`. If a tree is
  wedged, `treehouse return <path> --force`. `new-agent.py` already returns the
  lease itself if any later step fails.
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
