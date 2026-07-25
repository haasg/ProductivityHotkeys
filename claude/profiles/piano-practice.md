# piano-practice

## Repo

Browser-based piano practice app - plain HTML/JS, no build step and no Rust
despite what a stale copied skill may claim. Entry points are `index.html`,
`practice.html`, and `notation-studio.html`; the engine is `practice-engine.js`.
Also a teaching workspace: `curriculum/`, `lessons/`, `learning-records/`,
`MISSION.md`, and `RESOURCES.md` hold the user's own learning state, maintained
by the `teach` skill.

**Do not** apply Rust, crate, or `cargo` vocabulary here.

## Module vocabulary

- **Unit word:** module (an ES module / JS file)
- **Graph definition lives in:** the `import`/`<script>` graph rooted at the HTML
  entry points
- **A boundary change means:** a new module, a changed export surface, or a
  shifted responsibility between the practice engine and the UI layer

## Docs

- **Glossary:** `CONTEXT.md` at the repo root
- **Decisions:** `docs/adr/` - create lazily, only when the first ADR is needed
- **Invariants:** none maintained. If a cross-cutting invariant crystallises,
  propose creating `docs/ARCHITECTURE.md` rather than assuming it exists.
- **Learning state:** `MISSION.md`, `RESOURCES.md`, `curriculum/`,
  `learning-records/`. These belong to the `teach` workflow - a grill about app
  code should not edit them.

## ADR bar

Three-gate test, with gate #1 read as: reversing it touches **the persisted
practice/progress data format, or the audio and timing core that every lesson
depends on**. This is a small personal codebase - the bar for an ADR is high and
most decisions belong in a code comment or `CONTEXT.md`.

**Does NOT warrant an ADR:** lesson content, curriculum ordering, UI layout,
styling, or anything confined to one screen.

## Boundary ceremony

Light by default - single consumer, single author, cheap to reverse. Apply the
full pass only to the audio/timing core and the persisted progress format, where
a mistake is expensive to unwind.

**Enforcement tooling:** none. Record intent in the decision.

## Batch workflow

Not present. Skip every batch-conditional rule:

- No overlapped-grill doc staging - land doc updates inline as they crystallise.
- **Wrap-up options:** offer `/my-build-full` or `/my-handoff`, plus "start the
  implementation directly in this session."

## Handoff

- **Default branch:** `main`
- **Post-validation command:** none
- **Open a PR on completion:** yes, when on a non-default branch

## Build pipeline

None configured. `/my-build-full` must STOP and ask rather than launch here.
There is no build step, no test gate, and no proof driver defined yet; an
autonomous pipeline has nothing to gate on. If one is wanted, define at minimum a
check gate and a validation approach (likely: a static server + browser
screenshots) and fill in this section plus **Proof surface** and **PR & publish**.

## Domain lessons

- **Verify the toolchain before trusting a plan that names one.** This repo has
  no Rust and no build step; a copied `build-full` skill asserted `cargo check`
  gates here for weeks. If a plan or skill names a command, confirm it exists
  before building on it.
