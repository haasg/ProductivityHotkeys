# Keybind Cheat Sheet

One-page reference for the hotkeys in this repo, Mac and Windows side by side.

**The one idea that unifies everything:** `J K I L` is the arrow cluster
(**J**=←, **K**=↓, **I**=↑, **L**=→) at every layer. You hold a different
modifier depending on what you're driving:

| Layer | Mac | Windows | Drives |
|---|---|---|---|
| Cursor (global) | `Cmd` | `Alt` | Move the caret in any app |
| Multiplexer (herdr) | `Ctrl+Space` prefix, then `j/k/i/l` | same | Panes, tabs, workspaces |
| Editor splits (Neovim) | `Ctrl+j/k/i/l` | `Ctrl+j/k/i/l` | Move across vim splits + herdr panes as one grid |
| Neovim leader | `Space` | `Space` | Editing, LSP, git review |

---

## 1. Cursor movement (global)

Windows global layer = **AutoHotkey** (`PC/myHotkeys.ahk`, primary modifier `Alt`).
Mac global layer = **Hammerspoon** (`Mac/init.lua`, primary modifier `Cmd`).
Same JKIL cluster, different modifier.

| Action | Mac | Windows |
|---|---|---|
| Left / Down / Up / Right | `Cmd+j/k/i/l` | `Alt+j/k/i/l` |
| Select ← ↓ ↑ → | `Cmd+Shift+j/k/i/l` | `Alt+Shift+j/k/i/l` |
| Word left / right | `Alt+j` / `Alt+l` | `Ctrl+j` / `Ctrl+l` * |
| Hop several lines up / down | `Ctrl+i` / `Ctrl+k` (5 lines) | `Ctrl+i` / `Ctrl+k` (6 lines) * |
| Line start / end (Home / End) | `Cmd+u` / `Cmd+o` (or `Alt+u/o`) | `Alt+u` / `Alt+o` (or `Ctrl+u/o`) |
| Select to line start / end | `Cmd+Shift+u/o` (or `Alt+Shift+u/o`) | `Alt+Shift+u/o` |
| Page up / down | — | `Alt+h` / `Alt+n` |
| Copy / Paste | system `Cmd+c/v` | `Alt+c` / `Alt+v` |
| Select all | system `Cmd+a` | `Alt+a` |
| Rename (F2) | — | `Alt+r` |
| Enter / Return | `Cmd+e` | — |

\* On Windows the `Ctrl+j/k/i/l` word-jump / line-hop variants are **disabled
inside the terminal** so they don't shadow the herdr/vim pane-nav layer (see
layer 2). Use the real `Ctrl+←/→` for word jumps in a terminal.

Hammerspoon admin: reload config `Ctrl+Cmd+Alt+r`, toggle console `Ctrl+Cmd+Alt+y`.

---

## 2. herdr multiplexer

Prefix = **`Ctrl+Space`**. Tap the prefix, release, then press the key.
Bindings below are the configured set (`dotfiles/home/.config/herdr/config.toml`);
defaults are noted where unchanged. A few keys use `Cmd` on Mac — the Windows
equivalent is in the last column.

| Action | Key | Windows note |
|---|---|---|
| **Panes** | | |
| Focus pane ← ↓ ↑ → | `prefix + j/k/i/l` | |
| Split right (side by side) | `prefix + \` | |
| Split down (stacked) | `prefix + -` | |
| Close pane | `prefix + x` | |
| Zoom / fullscreen pane | `prefix + z` | |
| Cycle panes | `prefix + Tab` / `prefix + Shift+Tab` | |
| **Tabs** | | |
| New tab | `prefix + c` | |
| Close tab | `prefix + &` | |
| Next / prev tab | `prefix + n` / `prefix + p` | |
| Jump to tab 1-9 | `prefix + 1`…`9` | |
| **Workspaces** (one per worktree/agent) | | |
| Workspace picker (fuzzy) | `prefix + w` | |
| New workspace | `prefix + Shift+N` | |
| Prev / next workspace | `Cmd+h` / `Cmd+n` | `prefix + Shift+H` / `prefix + Shift+L` |
| Jump to workspace | `prefix + g` (goto) | |
| **Agents** (direct, no prefix) | | |
| Prev / next agent | `Ctrl+h` / `Ctrl+n` | |
| **Worktrees** | | |
| New worktree + start Claude | `prefix + Shift+C` | |
| Open existing worktree | `prefix + Shift+O` | |
| Remove focused worktree | `prefix + Shift+X` | |
| **Session / misc** | | |
| Copy mode | `prefix + y` | |
| Detach this client (leave session running) | `prefix + q` | |
| Help (all keys) | `prefix + ?` | |
| Reload config | `prefix + Shift+R` | |

**Copy mode** (after `prefix + y`): `v` / `Space` start selection, `y` / `Enter`
copy, `q` / `Esc` cancel.

> Detach (`prefix + q`) is how you close one terminal window without killing the
> session — the server, agents, and any other attached window keep running.

---

## 3. Universal pane / split navigation

`Ctrl+j/k/i/l` moves between herdr panes **and** Neovim splits as one grid
(j=←, k=↓, i=↑, l=→). When the focused pane is running nvim it moves vim
splits; otherwise it moves herdr panes. Works the same on both platforms.

---

## 4. Neovim (LazyVim)

Leader = **`Space`**. Editing keys are Windows-style so you can live in insert
mode; drop to normal mode (`Esc`) mainly for the Space menu. These configs port
across platforms (`PC/nvim/`).

**Editing**

| Action | Key |
|---|---|
| Insert / normal mode | `i` / `Esc` |
| Move cursor (any mode) | `Alt+j/k/i/l` (Mac: `Cmd`), real arrows |
| Select, Windows-style | `Alt+Shift+j/k/i/l` |
| Copy / cut / paste (selection) | `Ctrl+c` / `Ctrl+x` / `Ctrl+v` |
| Save (even from insert) | `Ctrl+s` |
| Undo / redo (even from insert) | `Ctrl+z` / `Ctrl+y` |
| Prev / next open file | `J` / `L` (normal mode) |
| Jump back (after `gd`/`gr`) | `Ctrl+=` |

**Navigate & review**

| Action | Key |
|---|---|
| Find files | `Space Space` |
| Live grep | `Space /` |
| Go to definition | `gd` |
| Diffview: working-tree changes | `Space g d` |
| Diffview: whole branch vs main | `Space g D` |
| File history (current file) | `Space g h` |
| lazygit (floating) | `Space g g` |

Inside diffview: `Tab` / `Shift+Tab` cycle files, `]c` / `[c` jump hunks.

---

## 5. lazygit

Launch with `lg` (alias) or `Space g g` from nvim. Uses stock lazygit
keybindings — press `?` any time for the context-sensitive list. Most-used:

| Action | Key |
|---|---|
| Stage / unstage file (or hunk in the staging view) | `Space` |
| Enter file to stage line-by-line | `Enter` |
| Commit | `c` |
| Push / pull | `P` / `p` |
| Branches panel | `b` |
| Discard changes | `d` |
| Help | `?` |

---

## 6. Shell aliases

Common aliases (`Mac/terminal-shortcuts` → `~/.zshrc`,
`PC/terminal-shortcuts` → `~/.bashrc`).

| Alias | Does | Mac | Windows |
|---|---|:-:|:-:|
| `home` | `cd ~` | ✓ | ✓ |
| `gnuke` | `git clean -df; git reset HEAD --hard` | ✓ | ✓ |
| `greset` | `git reset HEAD~1` | ✓ | ✓ |
| `gsta` | `git stash --include-untracked` | ✓ | ✓ |
| `gpp` | `git stash pop` | ✓ | ✓ |
| `gsave` | `git add . ; commit -m save ; push` | | ✓ |
| `gst` / `gco` / `gl` / `gp` | status / checkout / pull / push | | ✓ |
| `alias-open` / `alias-save` | edit / reload the shell rc | ✓ | ✓ |
| `z <dir>` | zoxide frecency jump | ✓ | ✓ |
| `lg` | lazygit | ✓ | ✓ |
| `git dft` | difftastic structural diff | ✓ | ✓ |

---

See [WORKFLOW.md](WORKFLOW.md) for the architecture behind the multiplexer /
editor / nav layers, and [README.md](README.md) for setup.
