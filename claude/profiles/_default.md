# Default profile

Fallback when no profile exists for this repo. It states the *contract* every
profile fills in. Copy this file to `<repo-key>.md` and replace the bracketed
parts to onboard a new repo.

The repo key is the basename of `git remote get-url origin`, minus `.git`
(so `https://github.com/haasg/PixelGenerator.git` -> `PixelGenerator`). It is
stable across worktrees, which is why it, and not the directory name, is the key.

When a shared skill lands here instead of a real profile, it should say so once
in its first message - "no profile for `<key>`; running generic" - and then use
the conservative defaults below.

---

## Repo

Unknown. Explore before assuming anything about layout or toolchain.

## Module vocabulary

- **Unit word:** module
- **Graph definition lives in:** unknown - infer from the codebase
- **A boundary change means:** adding, removing, or moving a module, or changing
  what it depends on

## Docs

- **Glossary:** `CONTEXT.md` at the repo root if present; `CONTEXT-MAP.md` at the
  root means multiple contexts, each with its own `CONTEXT.md`
- **Decisions:** `docs/adr/`, sequential `NNNN-slug.md`
- **Invariants:** `docs/ARCHITECTURE.md` if present
- Create any of these lazily - only when there is something real to write.

## ADR bar

Use the three-gate test in `ADR-FORMAT.md` unchanged. No repo-specific carve-outs.

## Boundary ceremony

Uniform: apply the moves in `BOUNDARY-DESIGN.md` in proportion to blast radius.
Load-bearing, multi-consumer, or hard-to-reverse boundaries get the full pass;
exploratory code gets "boundary deferred, let it emerge."

**Enforcement tooling:** none known. Record intent in the decision; do not build
tooling during a grill.

## Batch workflow

Not present. Skip every batch-conditional rule:

- No overlapped-grill doc staging - land doc updates inline as they crystallise.
- At wrap-up, offer `/my-build-full` and `/my-handoff` only.

## Handoff

- **Default branch:** detect with `git symbolic-ref refs/remotes/origin/HEAD`,
  falling back to `main`
- **Post-validation command:** none
- **Open a PR on completion:** only when the session is on a non-default branch

## Build pipeline

None configured - and unlike the other sections, `/my-build-full` does NOT run on
defaults. An autonomous pipeline that guesses its own gates is worse than none, so
a missing or "none configured" Build pipeline section means the skill stops and
asks. A real profile fills in:

- **Check gate:** the command that must be clean (build/typecheck), verbatim
- **Iteration tests:** the cheap scoped checks to run while iterating
- **Full gate:** the once-at-end gate, its expected duration, and any
  capture/foreground notes
- **Per-piece gate:** the gate each decomposed piece runs
- **Fmt:** the formatting command, or none
- **Doctrine files:** repo files every build worker must read in full
- **Worker agent types:** impl / light agent types from `.claude/agents/`, or
  none for the default workflow subagent
- **Decomposition note:** optional guidance on when splitting pays here

## Proof surface

None configured (`/my-build-full` stops without it). A real profile fills in: the
driver (how an agent runs and observes the app), machine-readable proof channels,
visual capture mechanics, the readiness check and what its failure means
(`blocked` vs `cant_prove`), prohibitions (focus stealing, visible surfaces),
debug levers, sanctioned gitignored evidence homes, and repo evidence lessons.

## PR & publish

None configured (`/my-build-full` stops without it). A real profile fills in: the
architecture-section format and unit vocabulary, the Try-it command, the evidence
bundle location (and how to discover it from a worktree), the publish command with
its credential source and fallback, and the merge-sync re-check commands.

## Domain lessons

None recorded yet. Add hard-won, repo-specific grill lessons here as they are
learned - each one line, with the incident that taught it.
