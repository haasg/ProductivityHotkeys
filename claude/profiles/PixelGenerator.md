# PixelGenerator

## Repo

Rust workspace. A deterministic game engine plus games built on it, driven by a
harness CLI so agents can play the running game. Shared agent standards live in
`AGENTS.md`, which imports `.agents/PRINCIPLES.md` and
`.agents/RUST_PROJECT_STRUCTURE.md`.

## Module vocabulary

- **Unit word:** crate
- **Graph definition lives in:** the workspace `Cargo.toml` plus each crate's
  `lib.rs` header doc-comment (one-sentence job, allowed dependencies, the
  higher-level verb it exposes)
- **A boundary change means:** a crate added / removed / moved, a changed
  dependency edge, a new process or thread, or a changed channel or its delivery
  semantics. These land in `Cargo.toml` and the `lib.rs` header - **not** in
  `docs/ARCHITECTURE.md`.

## Docs

- **Glossary:** `docs/CONTEXT.md`, indexed by `docs/CONTEXT-MAP.md` (multi-context
  repo - CONTEXT-MAP points at the per-game glossaries and design docs)
- **Decisions:** `docs/adr/`, split into per-area folders (engine, plus one per
  game), each with its own numbering - cite as "engine ADR 0031"
- **Invariants:** `docs/ARCHITECTURE.md`. The cross-cutting invariants are
  **determinism**, **state-outside-renderer**, the **impurity quarantine**, and
  **one-way-to-act**. A decision that adds or changes one of these updates
  ARCHITECTURE.md in the same pass.
- **Vision / verification ladder:** `docs/PROJECT.md` (§5 is the verification
  ladder; §5.4 governs when a new test is required)

Term index: `docs/CONTEXT.md` keeps a term index near its top, pinned by
`probe-vocab`'s `context_term_index` test. Every entry added or renamed updates
its index line too, and the pinning test runs before committing - a missed index
line turns the workspace gate red for the next worker.

## ADR bar

Three-gate test, with gate #1 read as: reversing it touches **multiple crates, a
cross-context contract, or the saved-state / snapshot format**.

**Does NOT warrant an ADR** (reversible in a single PR - home is a code comment,
the commit message, or `CONTEXT.md`):

- Gameplay balance and tuning - numbers, rates, costs, thresholds
- Visual / render choices - fog reads, draw order, colours
- Single-screen interaction defaults - what hover or click does on one screen
- Content models confined to one crate

Per-game gameplay decisions need a *much* higher reversal cost to qualify than
engine-line decisions. The engine line - process/IPC topology, determinism, state
tiers, cross-context contracts - is where ADRs earn their keep.

## Boundary ceremony

**Engine-vs-game is the primary, dominant lever.**

- **Engine / shared crates (`crates/engine/**`):** full, picky boundary pass.
  Multi-consumer, effectively permanent (a second game lifts them unchanged),
  high-leverage and low-reversibility.
- **Game-specific feature code (`games/<game>/**`):** much lighter touch. One
  consumer, cheap to reverse - don't stress the API. Escalate only when
  *promoting* something from a game toward engine (engine ADR 0002, "graduation
  on evidence").
- **Secondary axis (within either):** stability / blast-radius.

**Enforcement tooling:** none wired. Record the *intended* enforcement as part of
the decision so a later build task can implement it - which public surface to
snapshot (`cargo-public-api`), which dependency edges to forbid, where
`unreachable_pub` applies. There is no `architecture.toml` and no `cargo-deny`
config; the grill does not build the tooling.

## Batch workflow

**Present.** `.agents/batch/CURRENT` names the active batch; everything under
`.agents/batch/` is gitignored runtime state.

- **Overlapped grill:** if a slice worker is in flight on this branch, tracked-doc
  writes would race its commit. Stage instead of landing - draft each resolved
  update to `.agents/batch/<slug>/pending-docs/` the moment it crystallises, and
  land the drafts verbatim at the join, after the worker commits.
- **Pinned seams:** when the slice being grilled creates something a later slice
  will read, crystallise the narrow contract before wrap-up - exact names, types,
  semantics. It becomes the slice plan's **Pinned seams** section and a `batch.md`
  **Standing seams** entry. Pins are binding on the implementer; deviation is
  `blocked` and renegotiated, never silent.
- **Decisions ledger home:** inside a batch, the slice's `spec.md` ledger section
  (plus the design doc's Decided block); `batch.md` carries a one-line status and
  pointer, never recomposed prose.
- **Out-of-reach validation legs:** inside a batch, tag **capstone-owned** so the
  leg goes to the batch record for the seam audit's live scenario.
- **Wrap-up options:** inside an active batch, `/slice` is the only way a slice
  gets built. Outside a batch, offer `/my-build-full` or `/my-handoff`.

## Handoff

- **Default branch:** `main`
- **Post-validation command:** `cargo fmt -p <touched crates>` when `.rs` files
  changed
- **Open a PR on completion:** yes, when on a non-default branch (the usual case
  in a worktree)

## Build pipeline

- **Check gate:** `cargo check` plus a clean build.
- **Iteration tests:** touched crates only - `cargo test -p <crate> --bins` for
  binary crates (e.g. `probe`, `swarm`), `cargo test -p <crate> --lib` for
  library crates (e.g. `harness-control`) - paired with `cargo check`. This skips
  the slow cross-process harness itests.
- **Full gate:** `cargo test` (workspace), run ONCE after the last change; takes
  ~2-4 min; capture output as it runs
  (`cargo test --workspace 2>&1 | tee <scratchpad>/gate.log`). It runs the unit
  tests AND the cross-process harness itests (that real-socket coverage is the
  point) but not the `#[ignore]`d screenshot drivers - those write into
  `docs/validation/` and are run only by a human; never fold them into a gate.
- **Per-piece gate (decomposed builds):** `cargo check` plus
  `cargo test -p <crate>` INCLUDING integration targets (the `tests/` files), NOT
  just `--lib`/`--bins` - a `--lib`-only per-piece gate once let a multi-process
  deadlock ride latent through three passes (profiler-budgets retro).
- **Fmt:** `cargo fmt -p <touched crates>` before the final gate/commit. The
  repo's Stop hook reformats the workspace after an agent stops, so a
  not-fmt-clean commit re-dirties the tree for the next actor.
- **Doctrine files:** `.agents/PRINCIPLES.md`, `.agents/RUST_PROJECT_STRUCTURE.md`
  (a new concept's home is a new module/file named for it, not an append to the
  nearest existing lib.rs).
- **Worker agent types:** impl `build-worker`, light `build-worker-medium`
  (defined in `.claude/agents/`; they carry the standing gate-attestation,
  fmt, text-hygiene, and harness-lifecycle doctrine).
- **Decomposition note:** each parallel worktree pays a cold multi-minute cargo
  build; parallelize only substantial pieces - two big independent crates is a
  clear win, three small pieces in parallel is strictly worse than one sequential
  context doing them all.

## Proof surface

- **Driver:** the harness CLI - `scripts/harness.ps1 up` once, then one verb per
  call: `start --mode <running|paused> [--game <probe|swarm>] [--seed <n>]`,
  `read-state`, `hit-targets`, `click --x --y`, `move-cursor --x --y`,
  `step --ticks`, `screenshot`, `record-start`/`record-stop` (returns a GIF),
  the log surface (`log-query`/`log-count`/`log-exists`), and
  `game-status`/`stop`. `down` when done. Canonical verb reference:
  `crates/harness/harness-cli/README.md` - don't reverse-engineer verbs from
  source. It is NOT an MCP tool surface (removed; engine ADR 0009).
- **Game shape:** single-player, turn-based hex. Menu actions (new game, load
  save) are driven by `hit-targets` -> `click`, not dedicated verbs. There is NO
  multiplayer surface (no add-client/list-players).
- **Readiness:** `scripts/harness.ps1 up` must build and the daemon must be
  reachable. If not, the stage returns `cant_prove` and says why - never a silent
  pass.
- **Repo evidence lessons:**
  - Audio rows need a host-draining input: the sim-side `CosmeticEmitted` row is
    written during `step`, but `SoundPlayed` appears only when the host drains
    the effect outbox - a bare `step` never shows it. Reach the emitting tick via
    a real input verb (a `click`), or prove `CosmeticEmitted` live plus the
    event->sound mapping in unit tests.
  - Harness runs are silent - audio is muted on the same predicate that hides the
    window. A quiet test run is expected, not a sign nothing happened.
  - **NEVER pass `--visible on`** - it is the human-watch rig and puts the game
    window, with audio, on the user's desktop. If a scenario seems unreachable
    through the hidden harness, cover it in-code and record the named gap
    (`cant_prove` shape); never escalate to the visible rig.
  - The daemon is shared - leave it up when you finish. `stop` the game session
    before any `cargo build -p probe` (exe lock).
- **Sanctioned gitignored evidence homes:** the active batch folder when the task
  names one; the `<main-checkout>/validation/<slug>/` bundle dir; otherwise the
  scratchpad/temp.

## PR & publish

- **Architecture section:** crate ASCII tree - affected crates under their
  workspace path, tagged NEW/MODIFIED/REMOVED/MOVED, plus `new edges:` and
  `removed:` lines for cross-crate dependency changes from Cargo.toml deltas.
  Crate vocabulary per `.agents/RUST_PROJECT_STRUCTURE.md`.
- **Try it:** `cd <worktree abs path>` then `cargo dev` (the harness alias -
  never `cargo run -p <game>` directly).
- **Bundle location:** `<main-checkout>/validation/<slug>/` (gitignored there).
  Workers run in worktrees; discover the main checkout with
  `git rev-parse --git-common-dir` - its parent directory is the main checkout
  root. Never write the bundle into the worktree.
- **Publish command:**
  `tools\pr-report.exe publish <main-checkout>/validation/<slug>/ --repo PixelGenerator --pr <number> --title "<slug>"`.
  The five `R2`/`DOMAIN` env vars must be set; if missing, load them from the
  uncommitted `<main-checkout>/credentials/evidence-library.key` (never print the
  values). Full tooling contract: `.agents/skills/publish-evidence/SKILL.md`.
  Success prints exactly one line: the review URL.
- **Merge-sync re-check:** `cargo check` plus the touched crates' tests; textual
  conflicts -> the full `cargo test` gate instead. No live-validation re-run
  requirement.

## Domain lessons

### Repo-specific rules

- **Pin presentation beats for player-facing content.** When the plan adds
  player-visible Decisions, Incidents, or modals, structure alone under-specifies
  the build. Settle presentation at the grill, per beat: which existing
  window/machinery carries it, its firing order against windows that may already
  be open (a reveal triggered mid-Decision needs the deferred-pop path, not a new
  modal), and whether its body FITS the carrying window's authored geometry - read
  the longest body against the window's band/size constants DURING the session.
  (shipyard-release: four worker-surfaced presentation calls, one costing a full
  rework - a ~14-line reveal body against a flat 248px band sized years of content
  earlier.)
- **Copy approval covers the WHOLE beat, resolution included (probe ADR 0045).**
  A copy round approving an effect-carrying Decision row must bring its
  **Applied/resolution flavor line** and consequence-chip parity to the same
  approval as the card header/intro/labels. An Applied screen showing only bare
  effect lines ("+2 Fuel / Exploit +1") is a rule violation, not a style choice.
  (oasis-release: the omission cost a full user-prompted rework slice; the ADR now
  mandates the line, so a grill that skips it ships a known defect.)

### Incident log

Concrete instances of the shared skill's general rules, kept because the specifics
jog memory faster than the rule does:

- **graveyard-content s08 (2026-07-16)** - an announced once-per-system guard on a
  field that was actually run-persistent shipped a plan bug. Verify a property
  before pinning a decision on it.
- **supernova-design** - "estimate" and "flare" both collided with existing terms;
  the deferred collision check forced back-edits across two docs and still left
  residual informal usage.
- **graveyard-release s02** - the " - stands down" marker needed a NEW ordnance
  tooltip surface plus a new dev cheat. Existence-probe the carrying surface.
- **shipyard s07** - a "derive the kind from the id" premise went silently false
  once instances shared a kind; it survived the grill and blocked the build.
- **camp-cost hook** - a pinned signature named an enemy-position input its
  context-only shape couldn't carry. Enumerate the dynamic inputs.
- **s12 / s14** - s12 pinned a live-kill leg no slice could reach (12 HP vs a
  3-hull probe, visible in one const read); s14 pinned a principle already false
  for shipped content. Check pinned arithmetic against current consts in-grill.
- **forge slice-5 (2026-07-03)** - a grill fired from an unfilled handoff template
  burned heavy context-loading it could not use. Hence Step 0.
- **Coach 2026-07-11** - each ruling was being re-transcribed 4-5x per slice with
  drift. Hence the write-the-ledger-once rule.
