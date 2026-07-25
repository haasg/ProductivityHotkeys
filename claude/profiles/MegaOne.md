# MegaOne

## Repo

Roblox / Luau game. Rojo project (`MegaOne.project.json`), Luau source under
`src/`, Vide for UI, Python and shell tooling under `tools/`. Ships to a live
Roblox universe with a staging promotion flow (`docs/RELEASE.md`).

## Module vocabulary

- **Unit word:** module (a Luau `ModuleScript`)
- **Graph definition lives in:** the Rojo project files
  (`MegaOne.project.json`, `MegaOne.full.project.json`) plus the module tree
  under `src/`
- **A boundary change means:** a new service or controller, a changed remote
  event/function contract or its delivery semantics, or a shifted
  client/server ownership boundary

## Docs

- **Glossary:** `CONTEXT.md` at the repo root (single context - no CONTEXT-MAP)
- **Decisions:** `docs/adr/`, sequential `NNNN-slug.md`
- **Invariants:** `docs/ARCHITECTURE_MAP.md` - note the name differs from the
  usual `ARCHITECTURE.md`. It holds the high-level component diagrams plus the
  invariants every change must preserve.
- **Spec suite:** `docs/` carries a large per-feature spec set indexed by
  `docs/SPEC_INDEX.md` and `docs/INDEX.md`. Check the relevant spec before
  proposing behavior in an area it already covers.
- **Release flow:** `docs/RELEASE.md`
- **Validation:** `docs/VALIDATION_RUNBOOK.md`

## ADR bar

Three-gate test, with gate #1 read as: reversing it touches **multiple systems,
a client/server contract, or the saved player-data format**.

**Does NOT warrant an ADR** (reversible in a single PR - home is a code comment,
the commit message, or the relevant `docs/*_SPEC.md`):

- Gameplay balance and tuning - numbers, rates, costs, drop rates, thresholds
- Visual / UI choices confined to one screen
- Content additions that follow an existing pattern (a new weapon, a new powerup)

Player-data schema and remote contracts are where ADRs earn their keep: both are
expensive to reverse once players hold live data.

## Boundary ceremony

Proportional to blast radius, with the client/server line as the primary lever:

- **Anything crossing the client/server boundary** - remotes, replicated state,
  authority decisions: full, picky pass. Exploits and desync live here, and the
  contract is hard to change once shipped.
- **Server-authoritative systems touching player data:** full pass.
- **Client-only UI and presentation code:** lighter touch, one consumer, cheap to
  reverse.

**Enforcement tooling:** `tools/typecheck.sh` (Luau type checking) is the
available gate. Record any further intended enforcement in the decision; do not
build tooling during a grill.

## Batch workflow

Not present. Skip every batch-conditional rule:

- No overlapped-grill doc staging - land doc updates inline as they crystallise.
- No pinned-seams or capstone-owned tagging. An out-of-reach validation leg is
  named in the plan as a follow-up proof with its staging moment.
- **Wrap-up options:** offer `/my-build-full` or `/my-handoff`, plus "start the
  implementation directly in this session."

## Handoff

- **Default branch:** `main`
- **Post-validation command:** `tools/typecheck.sh`
- **Open a PR on completion:** yes, when on a non-default branch

## Build pipeline

- **Check gate:** `bash tools/typecheck.sh` - ZERO errors AND ZERO warnings. If
  its architecture-map check fails, run the regenerate command it prints (never
  hand-edit the generated map) and re-run.
- **Iteration tests:** the same `bash tools/typecheck.sh` - it is fast and
  whole-repo.
- **Full gate:** `bash tools/typecheck.sh`, clean, run once after the last
  change. Fast; no long-timeout ceremony needed.
- **Per-piece gate (decomposed builds):** `bash tools/typecheck.sh` clean.
- **Fmt:** none. Instead: every touched `.lua`/`.luau` file must keep `--!strict`
  at the top and stay fully annotated.
- **Doctrine files:** `docs/CLAUDE.md` (carries the Verification hard gate).
- **Worker agent types:** none - use the default workflow subagent.
- **Decomposition note:** the typecheck is fast and whole-repo, so decomposition
  buys context headroom, NOT build wall-clock - the bar for splitting is high.

## Proof surface

- **Driver:** an OPEN, MCP-attached Studio for the target place - MegaOne has no
  headless harness. The implementer proves runtime-observable behavior LIVE in a
  Studio the human leaves open, driving it via the Studio MCP plus
  `megasync-cli serve <place>` (pushes the uncommitted working-tree change into
  the open Studio, code-only, no new window), then stops and restarts the
  playtest (`start_stop_play(false)` then `(true)`) so the new code is picked up -
  code changes made mid-playtest are not.
- **Machine-readable proof:** `VLog.Log(subsystem, event, context?)` rows.
  `execute_luau` runs on the CLIENT, so the server-side log is only reachable via
  `ReplicatedStorage.ValidationLogRemotes.Query:InvokeServer(...)` - `GetJSON`,
  `Has(subsystem,event)`, `HasInOrder({...})`, `Count`, `WaitFor`, `Clear`.
- **Visual proof:** `CaptureService` screenshots (land in `screenshots/<slug>/`)
  and `CaptureService:StartVideoCaptureAsync` clips. For video, copy the `wob-*`
  file out of `%LOCALAPPDATA%\Roblox\tmp-capture-storage\` and rename to `.mp4`
  BEFORE stopping play - it is deleted the moment play stops. Capture recipe
  (full version in CLAUDE.md): fresh-camera swap, God Mode
  (`GameStateRemotes.DebugGodMode:FireServer()`), Pause
  (`DebugPauseRemotes.Control:InvokeServer("Pause")`), capture, pull the PNG off
  disk. NEVER a PowerShell desktop grab, a `megasync-cli screenshot` (no such
  verb), or the MCP `screen_capture` (saves no file). `CaptureService` only.
- **Readiness:** confirm with `bash tools/studio_preflight.sh` (or
  `list_roblox_studios` non-empty). A runtime-observable change with no attached
  Studio returns **`blocked`** naming the missing Studio - opening one is the
  human's job, not the run's. A pure type/refactor change with nothing observable
  needs no Studio (the typecheck stands in).
- **Code-only vs baked content:** `src/server`/`src/client`/`src/shared` changes
  are provable via `serve`. Baked-content-dependent changes (mobs / arenas /
  lighting under `src/studio/**`, mapped only in `<place>.full.project.json`)
  need a full `megasync-cli build`/`launch`, which opens a NEW Studio window - in
  tension with no-focus-stealing. For an unattended run, prove what `serve` +
  typecheck can, and name the content-dependent behavior as a gap needing a
  human full-build validation (the `cant_prove` shape for that portion). Never
  claim a content-baked behavior proven off a `serve` run that could not load it.
- **No focus stealing:** the human is working on the machine. Never open a new
  Studio window, foreground/focus a window, or launch a visible build to reach a
  state.
- **Human input path:** drive `user_mouse_input`/`user_keyboard_input` or the
  real client path; "`execute_luau` fired the remote and the server responded" is
  never evidence for a divergent human path.
- **Debug levers:** `GameStateRemotes.*`, `DebugShopOpenRemotes`, `DebugGodMode`,
  `DebugPauseRemotes`.
- **Sanctioned gitignored evidence homes:** `report-out/`, `screenshots/`.

## PR & publish

- **Architecture section:** module/subsystem ASCII tree over `src/`, tagged
  NEW/MODIFIED/REMOVED/MOVED. Call out a new subsystem prominently - a new
  Contract + Server Service (registered with `SubsystemLoader`, `Subsystem`
  suffix) + Client API + UI added to the boot order is a structural event
  (STRUCTURE.md). Under the tree, add lines for cross-cutting wiring: new
  `SubsystemLoader` registrations, boot-order / Place-Role changes, new `Remotes`
  folders, new Contracts, new Attributes. Vocabulary from `CONTEXT.md`: Place,
  Place Role, Subsystem, Contract, Client API, Renderer, Run/MatchSession.
- **Try it:** `cd <worktree abs path>` then `megasync-cli serve MegaOne` (push
  code into an already-open Studio) or `megasync-cli launch MegaGame` (full
  build, required for baked studio content).
- **Bundle location:** `<repo-root>/report-out/` (gitignored). Discover the root
  with `git rev-parse --show-toplevel`. Delete/regenerate the bundle between
  runs - publish uploads EVERYTHING in the directory. Media under
  `report-out/assets/` with relative `./assets/...` paths.
- **Publish command:** `bash tools/publish_report.sh <pr-number>` (defaults to
  the `report-out/` bundle; pass a bundle dir as `$2` to override; use `0` for
  ad-hoc evidence with no PR). The wrapper sources credentials from
  `C:/repo/EvidenceLibrary/.env.megaone.local` (override with
  `MEGAONE_REPORT_ENV`) - you do not set env vars by hand. Missing env file ->
  it exits 1 naming the path; keep the PR and reference `report-out/index.html`
  locally.
- **Merge-sync re-check:** `bash tools/typecheck.sh` AND re-run the live
  validation for the paths this change moved - a semantic conflict is invisible
  to git and the typecheck alone cannot see behavior.

## Domain lessons

None recorded yet. Add hard-won, repo-specific grill lessons here as they are
learned - each one line, with the incident that taught it.
