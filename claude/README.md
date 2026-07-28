# Shared Claude skills

One maintained copy of the skills I use across every repo, plus a per-repo profile
that carries the repo-specific detail. Version-controlled here so edits have
history and survive a machine.

```
claude/
  skills/          one directory per shared skill, junctioned into ~/.claude/skills
    _shared/       cross-skill doctrine (EVIDENCE.md), junctioned like a skill but not one
    my-grill/
    my-handoff/
  profiles/        one file per repo, junctioned to ~/.claude/skill-profiles
    _default.md    the contract every profile fills in, and the fallback
    PixelGenerator.md
    MegaOne.md
    piano-practice.md
  agents/          shared agent types the skills spawn, junctioned to ~/.claude/agents
    my-ticket-picker.md
```

## Why the `my-` prefix

Repo-local skills named `grill`, `handoff`, and `build-full` still exist in
several repos, some of them shared with teammates. The prefix means the shared
version never collides with a repo-local one, and it is obvious at the call site
which lineage you are invoking. `/my-grill` is this one; `/grill` is whatever the
repo ships.

## How a skill finds its profile

Every shared skill starts by resolving a **repo key**: the basename of
`git remote get-url origin`, minus `.git`. So
`https://github.com/haasg/PixelGenerator.git` gives `PixelGenerator`.

The key is the remote, not the directory name, because worktrees share a remote:
`PixelGenerator.worktrees/slot-1` resolves to `PixelGenerator` and gets the right
profile automatically.

The skill then reads `~/.claude/skill-profiles/<key>.md`. If there is no file for
the key it falls back to `_default.md` and says so once, rather than guessing at
the repo's toolchain.

## Adding a repo

Copy `profiles/_default.md` to `profiles/<repo-key>.md` and fill it in. Nothing
needs to be checked into the target repo, which is the point: the profile lives
here, so a repo shared with teammates never carries my personal skill config.

## Adding a machine

The skills and profiles are junctioned into place. From an ordinary (non-elevated)
PowerShell:

```powershell
$src = "C:\repo\ProductivityHotkeys\claude"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skill-profiles" -Target "$src\profiles"
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\agents" -Target "$src\agents"
Get-ChildItem "$src\skills" -Directory | ForEach-Object {
  New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\skills\$($_.Name)" -Target $_.FullName
}
```

Junctions, not symlinks: they need no Developer Mode and no elevation on Windows.

Skills are junctioned individually rather than junctioning the whole
`~/.claude/skills` directory, so the other global skills that are not yet
consolidated stay where they are and keep working. `agents/` is junctioned
whole, like `profiles/` - agent definitions are single files, and junctions are
directory-only, so a machine that already has a local `~/.claude/agents` should
first move those local agents into this repo (they get history and sync for
free) and then junction the directory.

## Status

| Skill | State |
|---|---|
| `my-handoff` | Consolidated from `PixelGenerator/.claude/skills/handoff` (Jul 6, the richest of four forks) |
| `my-grill` | Consolidated from `PixelGenerator/.claude/skills/grill` (Jul 22, the newest of seven forks) |
| `my-build-full` | Consolidated from `PixelGenerator/.claude/skills/build-full` (Jul 22) + the MegaOne fork (Jul 20). One static Workflow script; gates/proof/publish flow in from the profile as args. |
| `my-grab-ticket` | New (Jul 27). Grabs a ticket from the profile's **Work queue** (tracker CLI, grabbable states, claim verb), moves it to In Progress, hands it to `/my-grill` as the topic. Stops if the profile has no Work queue. Selection runs in the shared `my-ticket-picker` agent (`agents/`), pinned to low-effort Opus so picking never spends premium-model credits. |

`skills/_shared/` holds doctrine referenced by more than one skill - currently
`EVIDENCE.md`, the proof doctrine used by `my-build-full`'s pipeline and by
`my-handoff` when a profile sets **Publish an evidence report on completion:
yes** (e.g. MegaOne, where handoffs publish evidence but never commit). It has
no SKILL.md and is not invocable; the setup snippet above junctions it along
with the real skills.

`my-build-full` is stricter than the others about profiles: it requires the
**Build pipeline**, **Proof surface**, and **PR & publish** sections and STOPS if
any is missing - an autonomous pipeline must never guess its gates. Worker agent
types (e.g. PixelGenerator's `build-worker`) stay defined in each repo's
`.claude/agents/`; the profile only names them. Repo-agnostic agents that a
shared skill spawns itself (currently `my-ticket-picker`) live here in
`agents/` instead, since they carry no repo-specific doctrine.

Repo-local `grill` / `handoff` / `build-full` were left in place untouched.
