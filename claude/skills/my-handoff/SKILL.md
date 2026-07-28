---
name: my-handoff
description: Compact the current conversation into a handoff document, then automatically spawn a fresh-context agent that picks up the work from that document alone. Use when context is getting heavy and you want a clean-slate continuation seeded only by the doc.
argument-hint: "What will the next session focus on?"
---

# my-handoff

Compact the current conversation into a handoff document, then hand off to a
fresh-context agent that continues the work from that document alone.

A skill can't `/clear` the real session and reboot a top-level agent - that's a
human action with no tool behind it. Instead the continuation agent gets fresh
context *by construction*: it is seeded **only** by the handoff doc, never by this
conversation's history. That is the clean-slate restart. This session just writes
the doc and waits for the agent to finish.

## Step 0 - Load the repo profile

This skill is shared across repos; the repo-specific parts come from a profile.

1. Resolve the key: the basename of `git remote get-url origin`, minus `.git`
   (so `https://github.com/haasg/PixelGenerator.git` gives `PixelGenerator`). It
   is stable across worktrees. No git repo or no `origin`? Use the repo root
   directory name.
2. Read `$env:USERPROFILE\.claude\skill-profiles\<key>.md`.
3. If there is no file for the key, read `_default.md` from the same directory and
   say once, in one short line: "No profile for `<key>`; running generic - add one
   at `ProductivityHotkeys/claude/profiles/<key>.md`." Then continue.

From the profile this skill uses **Module vocabulary** (the unit word), **Docs**
(what to reference), and **Handoff** (default branch, post-validation command,
whether to open a PR, whether to publish an evidence report on completion).

## Step 1 - Write the handoff document

Write a handoff document that distills the current conversation into a
self-contained, executable plan. It is the **only** context the next agent has, so
anything not in it is lost. Save it to the OS temp directory (`$env:TEMP` on
Windows, `$TMPDIR` or `/tmp` elsewhere) - **not** the workspace.

Include, in order:

- **Objective** - 1-2 sentences: what's being built or changed, and why.
- **Current state** - what's already done vs. not yet started (this is a
  mid-stream handoff, not a clean start). Name the files and branches already
  touched so the agent doesn't redo or undo them.
- **Decisions & constraints** - the binding calls made during the conversation the
  agent must honor: libraries, boundaries between the profile's unit
  (crate/module/package), patterns to use or avoid, ADRs that apply. This is the
  highest-value section; it carries the alignment that would otherwise die with
  this context.
- **Remaining steps** - an ordered, actionable checklist, each step concrete
  enough to execute without re-deriving it.
- **Validation / done when** - how the agent confirms the work is correct and
  complete: the concrete checks, tests, or scenario to run. When the profile's
  **Handoff** section says **Publish an evidence report on completion: yes**,
  write this section concretely enough to drive the profile's **Proof surface**:
  the live scenario, the expected observable results, and what to screenshot or
  record - the continuation agent turns it into the published evidence.
- **References** - paths and URLs to the relevant code, ADRs, glossary terms,
  specs, or issues, using the locations named in the profile's **Docs** section.
  Reference them; do **not** duplicate their content.

Redact any sensitive information (API keys, passwords, PII). If the user passed
arguments, treat them as a description of what the next session will focus on and
tailor the doc accordingly. Keep it lean: enough for a cold agent to execute,
nothing more.

## Step 2 - Hand off to a fresh agent (no gate)

**Pin the continuation to Opus.** Spawn with `model: opus` by default, regardless
of this session's model, so a session on an expensive model (e.g. Fable) doesn't
silently carry that cost into the continuation work. Override to another alias
(`sonnet`/`haiku`/`fable`) only when the user has explicitly named a model for the
handoff.

Immediately, with no approval checkpoint, spawn the continuation agent **in the
foreground** via the `Agent` tool (`subagent_type: general-purpose`,
`model: opus`), seeded ONLY by the doc path:

> Read the handoff document at `<absolute path>`. It is a self-contained,
> executable plan and is the only context you have - do not assume any prior
> conversation. Execute it: work the remaining steps in order and validate per its
> **Validation / done when** section.

**PR on completion - branch sessions only.** Before spawning, compare
`git branch --show-current` against the profile's **Default branch**. If the
session is on any other branch (the usual case in a worktree) and the profile's
**Open a PR on completion** is yes, append to the prompt:

> When validation passes, run `<profile's post-validation command>`, commit the
> work on the current branch, and open a PR against `<default branch>` with
> `gh pr create`, then report the PR URL.

Drop the command clause entirely when the profile names no post-validation
command. On the default branch, append nothing: no PR, and the usual rule applies
(don't commit unless the user asked).

**Evidence report - profile-flagged, branch-independent.** If the profile's
**Handoff** section says **Publish an evidence report on completion: yes**,
additionally append to the prompt (on any branch, and independent of the PR
clause above):

> When validation passes, prove the change live: execute the handoff document's
> **Validation / done when** section per the shared proof doctrine at
> `$env:USERPROFILE\.claude\skills\_shared\EVIDENCE.md` and the profile's
> **Proof surface** section at `<abs path to the profile>` - read both in full
> first; they are binding. Capture named screenshots for anything visible and a
> recording for anything that moves. Assemble the evidence bundle at the
> profile's bundle location and publish it with the profile's publish command in
> its no-PR / ad-hoc form (both in the profile's **PR & publish** section), then
> report the review URL. Publishing uploads gitignored files only - it never
> commits, stages, or touches anything git-tracked, and the profile's git policy
> applies in full. If the proof surface's readiness check fails, stop and report
> what is missing instead of improvising a different proof.

This clause composes with, never replaces, the profile's commit/PR rules: a repo
can publish evidence while remaining strictly no-commit.

Do **not** paste the conversation, the doc's contents, or your own summary into
the prompt - the whole point is a clean context seeded only by the doc. When the
agent returns, relay its result in a sentence or two.
