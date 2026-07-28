---
name: my-build-full
description: Distill the current conversation's aligned plan into a lean executable doc, then run an autonomous Workflow - implement-and-self-prove -> plan-selected read-only reviewers (adversarial code / game-design) with confirmed defects fixed in-run -> a read-only retrospective that checks the build ran as the plan expected -> open a PR carrying the judgment findings as numbered Review notes - using fresh-context subagents. Ends with a post-PR triage step: the human picks which notes to address and a fresh subagent applies them on the same branch/PR. Repo-specific gates, proof surface, and publish mechanics come from the repo's skill profile. Stops and asks if a change is blocked or can't be proven without tooling that doesn't exist yet. Use after a grilling/planning session when you want to go from alignment to a reviewable PR without babysitting.
argument-hint: "<optional extra notes to pass through to the implementer>"
disable-model-invocation: true
---

# my-build-full

The heavyweight build. Go from an aligned plan to a reviewable PR in one command.
This skill distills the **current conversation** - typically a just-finished
grilling/planning session - into a lean, executable plan doc, then hands that doc
to the `Workflow` tool, which orchestrates an autonomous pipeline of fresh-context
subagents:

```
implement + self-prove --> review --> fix --> retro --> open PR --> post-PR triage (human)
        |                    |         |        |
        |                    |         |        +- did the build run as the plan expected? surface plan
        |                    |         |           holes, proof gaps, process issues, token/time waste -
        |                    |         |           and was the review decision itself right?
        |                    |         |           -> Process notes in the PR (advisory, read-only, never blocks)
        |                    |         |
        |                    |         +- only when the adversarial review CONFIRMED defects: fix them,
        |                    |            re-gate, re-prove -> the fixes make it INTO the PR;
        |                    |            unfixable -> the PR opens as a DRAFT
        |                    |
        |                    +- 0-2 read-only reviewers, picked at plan time per task shape (Step 1's
        |                       review decision): adversarial code review (confirmed defects -> fix
        |                       stage; judgment concerns -> Review notes) and/or game-design review of
        |                       the proof evidence (advisory Review notes); mechanical changes get neither
        |
        +- one agent by default; a decomposed plan (Step 2b) runs it as <=5 piece agents:
           parallel wave (isolated worktrees) > merge > sequential pieces > integrate-and-prove

implement can also exit early, no PR:
   +- blocked     (a verify step is impossible / plan is ambiguous / can't reach green) -> stop + report
   +- cant_prove  (proving it needs tooling that doesn't exist yet) ---------------------> stop + ask
```

The implementer **proves its own work** - it doesn't just pass the check gate, it
runs the plan's validation scenario on the repo's proof surface and records the
evidence for the **primary behavior and the plan's listed edge cases**. (In a
decomposed run - Step 2b - the "implementer" is several piece agents, and the
proving falls to a final integrate-and-prove stage on the accumulated tree.)

**Review is conditional, never flat-rate.** An always-on adversarial audit was
removed 2026-07-05 (across 31 runs it cost ~29% of a run's output tokens to catch
one real defect) - that data point is the guardrail this design answers. Step 1
decides per task which reviewers, if any, earn their seat. Reviewers read
artifacts (the plan, the diff, the proof evidence) instead of re-driving the game,
must tie every claimed defect to a concrete failure scenario, and are told an
empty review of a sound change is a good and honest result. Confirmed defects are
fixed in-run so they ship fixed inside the PR; judgment-grade findings ride to the
PR as numbered **Review notes** for the human to triage after the PR opens -
addressed on the same branch/PR, never a follow-up PR.

The **Retro** phase reads the run rather than writing the feature - on a run with
no reviewers it is the only second pair of eyes before the human. A fresh
read-only agent takes the plan, the implementer's outcome + proof artifact, the
reviewers' findings (when they ran), and the shipping diff, and **checks the
build proceeded as the plan expected**: every Done-when bullet has matching code
in the diff and evidence in the proof, the proof's claims are consistent with the
diff, the validation actually exercised the paths the diff moved, and the plan
itself held up. It also audits the run's **efficiency** from the stage
transcripts on disk, and - the meta-review lane - judges whether Step 1's
**review decision** was right for what actually shipped. Each finding carries a
**concrete recommendation**. The findings land in the PR as **Process notes** and
in the run report, as leads for you to investigate separately. It is **advisory
and read-only** - it never blocks the PR and never changes code.

You fire one command and walk away; you come back to a PR - with Review notes to
triage and Process notes attached - or to a clear report (blocked, or it can't be
proven without new tooling you should decide on). The PR is not the finish line:
the norm is the **post-PR triage step** (see After the pipeline) where the human
picks which judgment findings to address, a fresh subagent applies them on the
same branch/PR, and only then it merges - slam-merging a clean run is the
exception, not the habit. Every stage is a **fresh-context subagent seeded only
by the plan doc + the working-tree diff + the implementer's proof** - never the
grilling transcript, and never a resumed agent. The implementer's work persists
on the working tree, so each later stage just reads the diff off disk - and the
post-PR follow-up stays on subagents too, so the firing session's context never
absorbs the diff or the findings artifacts.

## Step 0 - Load the repo profile (gate)

This skill is shared across repos; every gate, proof driver, and publish command
comes from a profile. Unlike my-grill, this skill does NOT degrade gracefully - an
autonomous pipeline that guesses its own gates is worse than none.

1. Resolve the key: the basename of `git remote get-url origin`, minus `.git`. No
   git repo or no `origin`? Use the repo root directory name.
2. Read `$env:USERPROFILE\.claude\skill-profiles\<key>.md` **in full**.
3. The profile must contain all three of: **## Build pipeline**, **## Proof
   surface**, **## PR & publish** - and Build pipeline must not say "none
   configured". If anything is missing, **STOP - do not launch**. Tell the user
   which sections are missing and offer to draft them into
   `ProductivityHotkeys/claude/profiles/<key>.md` together first.

Also resolve `skillDir`: this skill's own directory
(`$env:USERPROFILE\.claude\skills\my-build-full`), used to hand subagents the
absolute path to [PR-FORMAT.md](./PR-FORMAT.md). And `sharedDir`: the shared
doctrine directory (`$env:USERPROFILE\.claude\skills\_shared`), home of the proof
doctrine [EVIDENCE.md](../_shared/EVIDENCE.md) that my-handoff also uses.

From the profile's **Build pipeline** section, extract the values Step 2 passes
into the script: the check gate, iteration tests, full gate, per-piece gate, fmt
command (or none), the doctrine files workers must read, and the worker agent
types (or none). Pass each command **verbatim** - do not paraphrase a gate.

## Preconditions

- **Auto mode.** Workflow subagents inherit your session's permission mode. If you
  are not in auto mode the pipeline stalls on prompts - that's on you. Note it
  once and proceed; do not try to elevate permissions.
- **Clean working tree, on the intended base branch.** The pipeline treats the
  *entire* working-tree diff as the change under review. Before launching, run
  `git status`; if the tree is dirty, stop and tell the user to commit/stash
  first - do **not** auto-stash silently. The PR branch is cut from the
  **current** branch and opened against the default branch, so launch from the
  default branch (or your intended base). Then sync the base before launching:
  `git fetch origin` and `git merge --ff-only @{u}`; if the fast-forward fails
  (local commits on the base), stop and sort it out with the user. And don't work
  in this repo while a run is live; the background pipeline shares this one
  working tree, and your edits would be swept into its commit.
- **Proof surface ready.** The profile's **Proof surface** section names the
  readiness check (a harness daemon, an attached Studio, a dev server) and what a
  stage returns when it's absent (`cant_prove` or `blocked`, naming why - never a
  silent pass). If the profile says readiness is the human's job (e.g. opening a
  Studio), verify it *before* launching rather than burning an implement attempt.
- **`gh` auth (for the PR).** If `gh` isn't authenticated the PR stage degrades:
  it commits to a local branch and reports "PR not opened: gh not authed" so
  nothing is lost.

This is meta/tooling work, not domain work: do **not** add this skill or its plans
to the repo's glossary or ADRs. Those are reserved for the product's domain
language and architecture decisions.

## When to use

**Only when the user explicitly invokes `/my-build-full`**
(`disable-model-invocation: true` enforces this). Never fire this skill
proactively - launching an autonomous multi-agent pipeline is the user's call,
even when the conversation looks fully aligned.

After grilling/planning, when alignment is high and you want a reviewable PR -
with a process retrospective attached - without babysitting. Standalone - does not
require a grill to have run; it distills whatever alignment exists in the current
conversation. If the conversation has little concrete alignment (especially no
validation strategy - see Step 1), say so plainly but still proceed if asked.

The pipeline ships the implementer's diff hardened only by the fix stage's
confirmed-defect fixes - it does **not** simplify or refactor the change. To
clean up the diff, run `/simplify` or `/code-review` by hand on the branch after
the PR opens.

## Step 1 - Write the plan doc

Distill the current conversation into an executable plan and write it to the OS
temp directory (e.g. `$env:TEMP` on Windows), filename like
`build-plan-<slug>-<YYYYMMDD-HHMMSS>.md`. It is the only thing the implementer
sees - make it self-contained.

**One shot - scope the whole feature, never a slice of it.** The plan must
describe the complete, working end state: everything needed for the objective to
be usable lands in this one plan, one PR. Do **not** cut the *deliverable* into
"Slice A / Slice B" or "foundation now, rest later" follow-up PRs. Decomposing the
*execution* is different and sanctioned: when the work has genuine seams, split
the build into pieces (Step 2b) that fresh contexts implement and one
integrate-and-prove stage validates - still one PR. (Ordered *executable steps
inside the one plan* are always fine - that's sequencing, not splitting.)

**Decomposition decision - make it here, deliberately.** After distilling, judge
two things: does the *complete* objective fit a single fresh implement-context,
implemented AND self-proven green - and does the work have real seams? The
profile's **Build pipeline** section may carry a decomposition note (e.g. "the
gate is fast and whole-repo, so decomposition buys context headroom, not
wall-clock - the bar for splitting is high"); honor it. Then pick one of three:

- **Single pass - the default.** Cohesive work that fits one context ships as one
  implement agent. Never decompose for its own sake: a piece that fails the seam
  test below adds merge/handoff overhead and buys nothing.
- **Decomposed build (Step 2b).** The work has genuine seams. Apply the **seam
  test** - a piece qualifies only if **all four** hold: **(a)** it sits on a
  nameable boundary (its own unit(s), in the profile's vocabulary, or a genuinely
  distinct stage of the work); **(b)** its file footprint is disjoint from sibling
  pieces (a shared file forces a dependency edge, or merging the two pieces);
  **(c)** it is independently green - the profile's per-piece gate passes with
  only its declared dependencies applied, via the additive-default discipline;
  **(d)** it is substantial enough that isolating it buys real context headroom -
  a piece worth a file or two of work is noise, fold it in. Write the **Pieces**
  section into the plan and pass `pieces` in Step 2's args. An in-cap
  decomposition needs no separate user authorization - the seam test and the
  5-piece cap are the guardrails.
- **Too big even decomposed - STOP. Do not launch.** If the objective will not
  fold into **at most 5** each-independently-green pieces, it does not belong in
  one PR (the script throws above 5 - never hand it a 6-piece plan and let it
  error out). Launching an oversized single pass anyway burns a whole implement
  attempt only to return `blocked` (this happened: ~104K tokens and a wasted human
  round-trip). Tell the user plainly, give a rough cost note, and work out a
  smaller scope together.

**Review decision - make it here, deliberately.** Review is earned per task,
never flat-rate (see the removed always-on audit above). Pick 0-2 reviewers from
this closed menu - never invent other reviewer types:

- **Adversarial code review** - enlist when correctness is subtle enough that a
  plausible-looking diff can be wrong in ways a green gate won't catch:
  determinism, algorithms, concurrency/multi-process work, state machines,
  boundary math, protocol/netcode. It hunts defects in the diff and must back
  every confirmed one with a concrete failure scenario; confirmed defects are
  fixed in-run before the PR, judgment-grade concerns become Review notes. Skip
  it for straightforward wiring and content work.
- **Game-design review** - enlist when the change moves player-facing behavior,
  feel, or visuals. It judges the proof evidence against the plan's **Design
  intent** as gameplay rather than code - and therefore requires that section to
  be written. Advisory only: everything it produces is a Review note. Skip it
  when nothing a player experiences changes.
- **Neither** - the default for mechanical/content-only changes (asset swaps,
  renames, config, doc moves): the retro alone is the second read.

The profile's **Build pipeline** section may carry a review note (e.g. "most
changes here are player-facing - lean design-reviewer-in"); honor it. Write the
picks and a one-line rationale into the plan's **Review decision** line and pass
them as Step 2's `reviews` args. The retro audits this decision against what
actually shipped - that feedback loop, not upfront caution, is how the selection
criteria stay honest.

**Ticket linkage.** If this conversation claimed a work-queue ticket (the usual
path: `/my-grab-ticket` -> grill -> this skill), the run closes it when the PR
opens. From the profile's **Work queue** section resolve two commands for that
ticket ID, verbatim per the CLI it names: the close command (the verb that moves
it to Done) and the note command (how to post a comment). Pass them as Step 2's
`ticket` args. No claimed ticket in the conversation, or no Work queue section in
the profile -> omit `ticket` entirely; never guess an ID. The ticket does NOT go
into the plan doc - only the PR stage acts on it.

Sections, in order:

- **Objective** - 1-2 sentences max: what we're building and why. No personas, no
  business case. The retro checks the shipped diff against *this*, so make it
  crisp - it is the check against an implementation that merely games the
  validation scenario.
- **Context references** - paths to the glossary terms, decision records, and
  invariants this work touches, at the locations the profile's **Docs** section
  names. Reference, do not duplicate.
- **Constraints & decisions** - the specific calls made during alignment the
  implementer must honor (libraries, unit boundaries, patterns to use/avoid). The
  distilled grilling output; the highest-value section.
- **Known edge cases & regression risks** - the edges, boundaries, and adjacent
  behaviors that could break or regress, captured during grilling. This is fed to
  the **implementer** so it builds them in and self-proves them - review is
  conditional and may not run, so an edge nobody names here may get proven by
  nobody; err on the side of listing them. An edge the Validation plan cannot reach live must say here how it
  WILL be evidenced (a named test, or an explicit "accepted untestable" line) -
  decide the gap at plan time instead of leaving the implementer to discover it at
  proof time.
- **Review decision** - *always.* One line: which reviewers this run gets
  (adversarial / design / both / none) and why. The retro audits this call
  against what actually shipped, so record the reasoning, not just the picks.
- **Design intent** - *design-review runs only; omit otherwise.* The
  gameplay-facing expectations the evidence will be judged against: what the
  change should feel and read like on screen, and what would look wrong (scale,
  readability, pacing, feedback, contradiction with the game's documented
  design). The design reviewer sees only this doc and the proof evidence - the
  grill conversation where this intent lives is NOT available to it, so distill
  the intent here or the review can only shrug.
- **Executable steps** - an ordered checklist. Each step pairs an action with a
  concrete verification: `N. <action> -> verify: <concrete check>`. A build
  sequence, not a spec to negotiate.
- **Pieces** - *decomposed builds only (Step 2b); omit for a single pass.* The
  piece list: each piece gets a one-line description, the units/files it
  **owns**, and `needs:` (the pieces it builds on, or `-`). Mark nothing else -
  the dependency-free pieces are the parallel wave, the rest run sequentially in
  dependency order. Each description must stand alone: a fresh agent builds that
  piece from the plan doc plus its line, so "wire A+B into the app" beats
  "part 3".
- **Validation plan** - *required.* How this change will be **proven** to do what
  it set out to, written against the doctrine in
  [EVIDENCE.md](../_shared/EVIDENCE.md) and
  the repo's proof drivers in the profile's **Proof surface** section. The
  implementer runs this to self-prove the primary behavior and the listed edges;
  it is the only live validation the run gets - so it must be concrete and
  reproducible:
  - **Reality-check the scenario against HEAD, and close the seeding list.** When
    a validation step names an entity, a content condition, or assumes an existing
    behavior, verify it exists at HEAD - grep the roster/content/path and cite the
    file; an impossible instruction invites a rationalized proof. And name the
    sanctioned condition-seeding levers as a CLOSED list (a fixture, specific
    debug commands - or none): the implementer never self-authorizes an unlisted
    lever, it records any deviation instead.
  - The live scenario to run, with the expected observable results (state reads,
    log rows, attribute values - whatever the profile's proof surface exposes) -
    or the check/test-gate runs that stand in when nothing is observable. Per
    EVIDENCE.md: reach observable behavior live, name the screenshots for anything
    visible AND the recording for anything that moves, back up any "unreachable
    visual" claim with a read-time assertion, and name any missing validation
    tooling here so the stage returns `cant_prove` instead of building it.
  - **Capture screenshots.** The implementer's shots evidence the primary behavior
    and each edge it reaches; the PR stage assembles them into the evidence bundle
    per the profile's **PR & publish** section. The stage itself writes only to
    temp, in its own stage-unique subdir.
  - **Spell out the human-input-path obligation per surface.** For every
    interactive surface the change adds or alters, state EVIDENCE.md's (a)-or-(b)
    explicitly - so the implementer self-proves it and the retro can check it. A
    silently-accepted driver-vs-human divergence is the single most likely way
    this pipeline ships a green-but-broken change.
- **Out of scope** - a short list of things explicitly *not* to do, to stop
  gold-plating.
- **Done when** - top-level success criteria: specific tests/behaviors, plus the
  profile's check gate and full gate clean. Only require a new test where a real
  behavior justifies locking it in - don't mandate speculative tests.

Keep it lean and engineering-shaped. No PM ceremony.

## Step 2 - Run the Workflow (no gate)

Immediately, with no approval checkpoint, call the `Workflow` tool with the script
below, passing:

```
args: {
  planPath: "<abs path to plan doc>",
  slug: "<kebab slug of Objective>",
  notes: "<skill arguments, or empty>",
  profilePath: "<abs path to the profile file>",
  skillDir: "<abs path to this skill's directory>",
  sharedDir: "<abs path to the shared doctrine directory>",
  gates: {
    check: "<profile: check gate, verbatim>",
    iter:  "<profile: iteration tests, verbatim>",
    full:  "<profile: full gate, verbatim, incl. duration/foreground notes>",
    piece: "<profile: per-piece gate, verbatim>",
    fmt:   "<profile: fmt command, or empty string>"
  },
  doctrine: "<profile: doctrine files, comma-separated repo paths, or empty>",
  reviews: { adversarial: <true|false>, design: <true|false> },
  ticket: { id: "<work-queue ticket ID>",
            close: "<the profile's Work queue close command with the ID substituted, verbatim>",
            note: "<the profile's Work queue note/comment command for this ID; the PR stage supplies the text>" },
  agents: { impl: "<agent type or null>", light: "<agent type or null>" }
}
```

Omit `ticket` entirely when the conversation claimed no work-queue ticket (see
Step 1's ticket linkage).

`reviews` carries Step 1's review decision verbatim - both false (or the key
omitted) means no Review phase, which is the correct call for mechanical work,
not a degraded run.

For a decomposed build (Step 1's decomposition decision) additionally pass
`pieces`; see Step 2b. Same script.

**The pipeline runs on Opus by default, regardless of the firing session's
model.** The script defaults its subagents' model to `opus`, so a grill run on an
expensive model (e.g. Fable) does not silently carry that cost into the
token-heavy implement stage. Leave `model` out of `args` for the Opus default;
pass `model: "<alias>"` **only** when the user has explicitly named a build model
for this run.

**Pass `args` as an actual JSON object, not a stringified one.** If it arrives as
a string, `args.planPath` is `undefined` and the implementer is told to "implement
the plan at undefined" - it will (correctly) refuse. The script normalizes a
stringified `args` and hard-fails if `planPath` or the gates are missing, so a
delivery failure stops loud instead of self-healing into the wrong change.

```javascript
export const meta = {
  name: 'my-build-full',
  description: 'Implement and self-prove an aligned plan doc, review it per the plan\'s review decision (fixing confirmed defects in-run), retro the run, open a PR',
  phases: [
    { title: 'Implement' },
    { title: 'Review' },
    { title: 'Retro' },
    { title: 'PR' },
  ],
}

// args may arrive as a real object or, depending on how it was passed, as a JSON string. Normalize, then fail loud.
const A = typeof args === 'string' ? JSON.parse(args) : (args || {})
const PLAN = A.planPath
const SLUG = A.slug
const NOTES = A.notes || ''
const PROFILE = A.profilePath
const SKILLDIR = A.skillDir
const SHAREDDIR = A.sharedDir
const G = A.gates || {}
const DOCTRINE = A.doctrine || ''
const AGENTS = A.agents || {}
const REV = A.reviews || {}   // Step 1's review decision; both false = no Review phase, deliberately.
const TICKET = A.ticket || null   // work-queue ticket this run ships (Step 1's ticket linkage); null = none claimed.
const MODEL = A.model || 'opus'   // build stages pin to Opus by default; override only via an explicit args.model.
// Decomposed build (Step 2b): pieces = { parallel: [...], sequential: [...] }; absent/empty = single-pass.
let PAR = (A.pieces && Array.isArray(A.pieces.parallel)) ? A.pieces.parallel : []
let SEQ = (A.pieces && Array.isArray(A.pieces.sequential)) ? A.pieces.sequential : []
if (PAR.length === 1) { SEQ = [PAR[0], ...SEQ]; PAR = [] }   // a "parallel wave" of one is just the first sequential piece - skip the worktree overhead
const TOTAL = PAR.length + SEQ.length
if (!PLAN) throw new Error('my-build-full: planPath missing from args - pass args as a real object, not a stringified one (see Step 2).')
if (!PROFILE || !SKILLDIR || !SHAREDDIR) throw new Error('my-build-full: profilePath/skillDir/sharedDir missing from args - Step 0 resolves all three.')
if (!G.check || !G.full) throw new Error('my-build-full: gates.check/gates.full missing - the profile\'s Build pipeline section is incomplete; fix the profile, do not guess gates.')
if (TOTAL > 5) throw new Error('my-build-full: decomposed build is capped at 5 pieces - if the seams yield more, the objective is too big for one PR; rescope with the user (see Step 2b).')

// Worker agent types are optional profile config; omit agentType entirely when the repo defines none.
const AG = (t) => t ? { agentType: t } : {}

const IMPL_SCHEMA = {
  type: 'object',
  required: ['outcome', 'summary'],
  additionalProperties: false,
  properties: {
    outcome: { enum: ['proven', 'done', 'cant_prove', 'blocked'] },
    summary: { type: 'string', description: 'one paragraph: what changed and how the gate was met (piece/merge stages return done = greened, not proven)' },
    proofPath: { type: 'string', description: 'path to the self-proof artifact in temp (proven only)' },
    treePath: { type: 'string', description: 'absolute path of the git worktree the work sits in (parallel piece only)' },
    missingTooling: { type: 'string', description: 'what validation surface is missing (cant_prove only)' },
    blocker: { type: 'string', description: 'the specific blocker (blocked only)' },
  },
}

const ADV_SCHEMA = {
  type: 'object',
  required: ['summary', 'findingsPath', 'mustFix', 'notes'],
  additionalProperties: false,
  properties: {
    summary: { type: 'string', description: '1-2 sentences: the headline, or that the diff looks sound' },
    findingsPath: { type: 'string', description: 'path to the full findings markdown in temp' },
    mustFix: {
      type: 'array',
      description: 'CONFIRMED defects only - each with a failure scenario the fix stage will re-check; judgment-grade concerns belong in notes',
      items: {
        type: 'object',
        required: ['title', 'repro'],
        additionalProperties: false,
        properties: {
          title: { type: 'string', description: 'one line naming the defect' },
          repro: { type: 'string', description: 'the concrete failure scenario: specific inputs/state -> the wrong observable outcome, traced through the diff' },
          pointer: { type: 'string', description: 'file:line or diff hunk' },
        },
      },
    },
    notes: { type: 'array', items: { type: 'string' }, description: 'judgment-grade findings for the PR Review notes, one line each: the concern + a pointer' },
  },
}

const DESIGN_SCHEMA = {
  type: 'object',
  required: ['summary', 'findingsPath', 'notes'],
  additionalProperties: false,
  properties: {
    summary: { type: 'string', description: '1-2 sentences: the headline, or that the evidence matches the design intent' },
    findingsPath: { type: 'string', description: 'path to the full findings markdown in temp' },
    notes: { type: 'array', items: { type: 'string' }, description: 'gameplay-judgment findings for the PR Review notes, one line each: what looks off + which evidence item (or missing capture) shows it' },
  },
}

const RETRO_SCHEMA = {
  type: 'object',
  required: ['summary', 'reviewPath'],
  additionalProperties: false,
  properties: {
    summary: { type: 'string', description: '2-3 sentences for the run report: the headline of what was surfaced, or that nothing notable came up' },
    reviewPath: { type: 'string', description: 'path to the findings markdown in temp, for the PR to inline' },
    topFinding: { type: 'string', description: 'the single most worth-investigating item, if any - paired with its recommended action' },
  },
}

// Shared preamble: repo doctrine + the proof doctrine + the repo profile. Every implementing stage gets it.
const READS = `This repo's standing agent instructions (CLAUDE.md / AGENTS.md) apply.
Before implementing, READ IN FULL and follow - open them yourself, do not assume they are in your context:
${DOCTRINE ? `- this repo's doctrine files: ${DOCTRINE}\n` : ''}- the shared proof doctrine at ${SHAREDDIR}/EVIDENCE.md - live proof over stand-ins, screenshots/video defaults, the human-input-path rule, unreachable visuals, missing tooling, the test gate vs. iteration loop, evidence hygiene
- the "Proof surface" section of the repo profile at ${PROFILE} - this repo's proof drivers, readiness checks, debug levers, evidence homes, and hard-won evidence lessons; it is binding
Register every NEW source file with \`git add -N <file>\` the moment you create it (standing doctrine: new-file
visibility) - an unregistered new file is invisible to the \`git diff\` later stages review.`

const implPrompt = () => `Implement the plan at ${PLAN}, then PROVE it works yourself. It is self-contained - read it fully first.
${READS}
Honor the plan's **Constraints & decisions**, **Known edge cases & regression risks**, and **Out of scope** exactly,
and the repo's documented cross-cutting invariants (the profile's Docs section names where they live). Work the
**Executable steps** in order, running each step's verify: check - and build in and self-prove the listed edge cases,
don't just cover the happy path.

Get to green in THIS context - implement, run, observe, fix, repeat. Do not hand off broken or unproven work:
1. The check gate must be clean: ${G.check}
2. Tests, per EVIDENCE.md's "Test gate vs. iteration loop": while iterating, run only the cheap iteration checks -
   ${G.iter || G.check} - then run the FULL gate ONCE, after your last change: ${G.full}. It must be green. You own
   not breaking unrelated behavior, not just your new scenario - the one full run is that proof; per-edit full runs
   are waste. Run the final gate as ONE synchronous foreground shell call with a generous timeout, output captured
   to a file - never in the background.
3. Execute the plan's **Validation plan** yourself, per EVIDENCE.md and the profile's Proof surface: reach
   observable behavior LIVE using the profile's drivers; capture named screenshots for anything visible and a
   recording for anything that moves; prove interactive surfaces on the human input path; back up any "unreachable
   visual" claim with a read-time assertion. Derive the live scenario from what THIS diff changed - the plan's
   scenario is the floor, not the ceiling, and a standard demo ride proves nothing about the paths you moved unless
   it exercises them with NON-DEFAULT values. Every live-reachable observable you cover only with a unit test is a
   gap the retro is instructed to flag - go live for each one you can reach.
4. Write your proof - the exact scenario you ran and the concrete observed results - to an artifact in YOUR OWN
   stage-unique subdir of the OS temp dir: create \`build-${SLUG}-impl\` under \`$env:TEMP\` / \`%TEMP%\` and write
   everything there, copying your screenshots into it too (the evidence-hygiene rule in EVIDENCE.md is binding -
   never write into the repo tree except the profile's sanctioned gitignored homes, never use fixed shared-temp
   names). List each screenshot's absolute path and a one-line caption of what it shows (these become the published
   evidence page). Return the artifact path as proofPath.

Leave ALL source changes UNCOMMITTED on the working tree - do not commit, push, or write a report into the repo.

Return exactly one outcome:
- "proven": implemented; check gate and full gate green; the Validation plan scenario ran and matched. Set proofPath.
- "cant_prove": proving it would need validation tooling that does not exist yet - do NOT build it. Set missingTooling.
- "blocked": a verify step is impossible, the plan is ambiguous or contradicts a documented decision, or you cannot
  reach green (including: the profile's proof-surface readiness check fails and its Proof surface section says that
  is a blocker). Set blocker to the specific reason. Do NOT guess, fake success, or claim "proven" without running
  the scenario.
${NOTES ? `\nExtra notes: ${NOTES}` : ''}`

// Decomposed build (Step 2b): <=5 pieces on real seams. The parallel wave is the dependency-free pieces, each in an
// isolated worktree cut from committed HEAD - which is exactly why only dependency-free pieces may parallelize: a
// worktree cannot see other pieces' uncommitted work. A merge step applies their diffs onto the primary tree; the
// sequential pieces then accumulate on it. Pieces gate on the profile's per-piece gate; only the integrate-and-prove
// stage runs live validation + the single full gate and writes the proof artifact the retro/PR read.

const parPrompt = (idx, desc) => `You are implementing ONE PIECE of a DECOMPOSED build of the plan at ${PLAN}. It is self-contained - read it fully first.
${READS}
Honor the plan's **Constraints & decisions**, **Known edge cases & regression risks**, and **Out of scope**.

This piece implements ONLY: ${desc}
You are in an ISOLATED GIT WORKTREE, running in parallel with ${PAR.length - 1} sibling piece agent(s) in their own worktrees. You
cannot see their work and must NOT depend on it or drift into their footprint - the plan's **Pieces** section says what each piece
owns; stay inside yours. Use the additive-default discipline (defaults, always-defined types/symbols whose interiors are gated) so
your worktree PASSES THE GATE on its own even though the sibling pieces are not present in it.

Your gate - the integrate-and-prove stage, not you, runs live validation and the single full gate:
1. The check gate must be clean in your worktree: ${G.check}
2. Run the per-piece gate: ${G.piece || G.check}. Do NOT run the full gate and do NOT run live validation.

Leave ALL changes UNCOMMITTED in your worktree - do not commit, push, or write a report into the repo.

Return exactly one outcome:
- "done": this piece is implemented, its gate is green, and your worktree passes the check gate. Set treePath to your
  worktree's absolute path (\`git rev-parse --show-toplevel\`). Do NOT claim "proven" - live validation is the
  integrate-and-prove stage's job.
- "cant_prove": proving the plan would need validation tooling that does not exist yet - do NOT build it. Set missingTooling.
- "blocked": your piece is ambiguous, contradicts a documented decision, or you cannot reach green. Set blocker. Do NOT
  guess or fake success.
${NOTES ? `\nExtra notes: ${NOTES}` : ''}`

const mergePrompt = (wave) => `You are the MERGE step of a decomposed build. ${wave.length} parallel piece agents each finished in an isolated git
worktree; integrate their work onto THIS primary working tree. You implement nothing new.

Worktrees to merge, in order:
${wave.map((r, i) => `${i + 1}. ${r.treePath} - ${PAR[i]}`).join('\n')}

For each worktree, in order:
1. Stage everything there so NEW FILES are included in the patch: \`git -C <worktree> add -A\`, then export it:
   \`git -C <worktree> diff --cached --binary > $env:TEMP\\build-${SLUG}-piece-<n>.patch\`.
2. Apply here: \`git apply --3way <patch>\`. The pieces were planned with disjoint footprints, so conflicts should be rare and
   mostly manifest/lockfiles - resolve them preserving BOTH pieces' changes; for a generated lockfile prefer regenerating (via
   the check gate) over hand-merging.
3. After a clean apply, remove that worktree: \`git worktree remove --force <worktree>\`.

Then prove the merged tree holds together: check gate clean (${G.check}), and the merged pieces' per-piece gate green
(${G.piece || G.check}). Fix mechanical merge fallout yourself; if two pieces genuinely conflict in design, return "blocked"
naming both pieces - do NOT redesign either.

Leave ALL changes UNCOMMITTED on this tree - do not commit, push, or write anything into the repo. If you return "blocked",
leave the not-yet-merged worktrees in place for inspection and name their paths in the blocker.

Return "done" (all merged + green) or "blocked" (set blocker).`

const seqPrompt = (idx, desc) => `You are SEQUENTIAL PIECE ${idx} of ${SEQ.length} of a DECOMPOSED build of the plan at ${PLAN}. It is self-contained - read it fully first.
${READS}
Honor the plan's **Constraints & decisions**, **Known edge cases & regression risks**, and **Out of scope**.

This piece implements ONLY: ${desc}
Earlier pieces' changes${PAR.length ? ` (including a ${PAR.length}-piece parallel wave, already merged)` : ''} are ALREADY on the
working tree, UNCOMMITTED - run \`git diff\` first to see what is done, then build ON it (do not redo or revert it). Use the
additive-default discipline so the tree still passes the check gate at the end of your piece even though later pieces are not
built yet.

Your gate - the integrate-and-prove stage, not you, runs live validation and the single full gate:
1. The check gate must be clean: ${G.check}
2. Run the per-piece gate: ${G.piece || G.check}. Do NOT run the full gate and do NOT run live validation. (Run the per-piece
   gate as specified - a narrowed shortcut once let a real defect ride latent through three passes.)

Leave ALL changes UNCOMMITTED on the working tree - do not commit, push, or write a report into the repo.

Return exactly one outcome:
- "done": this piece is implemented, its gate is green, and the tree still passes the check gate. Do NOT claim "proven" - live
  validation is the integrate-and-prove stage's job.
- "cant_prove": proving the plan would need validation tooling that does not exist yet - do NOT build it. Set missingTooling.
- "blocked": a verify step is impossible, the plan/piece is ambiguous or contradicts a documented decision, or you cannot reach
  green. Set blocker. Do NOT guess, fake success, or claim success without running the gate.
${NOTES ? `\nExtra notes: ${NOTES}` : ''}`

const provePrompt = () => `You are the INTEGRATE-AND-PROVE stage of a decomposed build of the plan at ${PLAN}. Earlier piece agents implemented the
WHOLE plan on this working tree, UNCOMMITTED - run \`git diff\` plus \`git status --porcelain\` to see the accumulated change
(untracked \`??\` files are part of it; \`git add -N\` any the pieces missed). You own proving it works; you implement no new
features.
${READS}

1. The check gate must be clean: ${G.check}
2. Run the FULL gate ONCE - ${G.full} - it must be green. This single run is the proof the whole accumulated tree holds
   (it covers what the per-piece gates deliberately did not). Integration seams between pieces are yours: fix small
   cross-piece fallout to get there, but if a piece needs real rework, return "blocked" instead of rebuilding it. Run it as
   ONE synchronous foreground shell call with a generous timeout, output captured to a file - never in the background.
3. Execute the plan's **Validation plan** LIVE per EVIDENCE.md and the profile's Proof surface - drive the scenario, reach
   observable behavior, capture named screenshots and recordings, prove every interactive surface on the human input path,
   back any "unreachable visual" claim with a read-time assertion. Derive the live scenario from what the WHOLE accumulated
   diff changed - a standard demo ride proves nothing about the paths the pieces moved unless it exercises them with
   NON-DEFAULT values.
4. Write your proof (the exact scenario + concrete observed results for the whole feature) into your stage dir
   \`build-${SLUG}-impl\` under \`$env:TEMP\` / \`%TEMP%\`, copying your screenshots in; list each screenshot's absolute path
   and a one-line caption (these become the published evidence page). Return that path as proofPath.

Leave ALL changes UNCOMMITTED - do not commit, push, or write a report into the repo.

Return exactly one outcome:
- "proven": check gate clean; the full gate green; the Validation plan scenario ran LIVE and matched. Set proofPath.
- "cant_prove": proving it would need validation tooling that does not exist yet - do NOT build it. Set missingTooling.
- "blocked": you cannot reach green, or the accumulated diff needs real rework. Set blocker. Do NOT guess or fake success.
${NOTES ? `\nExtra notes: ${NOTES}` : ''}`

const advPrompt = (implProofPath) => `You are an ADVERSARIAL CODE REVIEW of the uncommitted change on this working tree - a defect hunt, not a style
review. You are READ-ONLY: do not modify the tree, do not run live validation, do not write anything into the repo.

The plan is at ${PLAN} - read it fully. The implementer's self-proof is at ${implProofPath} (in temp) - read it to see
what was claimed and proven; what it did NOT exercise is where defects hide. See the change itself with \`git diff\`,
cross-checked against \`git status --porcelain\` - any untracked (\`??\`) source file is part of the change the diff
does not show; read it directly.

Hunt for real defects a green gate would miss: logic errors; boundary/edge failures (start from the plan's **Known
edge cases & regression risks** - is each actually handled in code, not just claimed?); violated **Constraints &
decisions**; regressions in adjacent behavior the diff touches; state that can go inconsistent across the paths the
diff moved; error paths that swallow failures. Trace each suspicion through the actual code until it is confirmed or
dies - never report a hunch as a defect.

Sort what survives into exactly two buckets:
- **mustFix** - CONFIRMED defects only. Each needs a concrete failure scenario (specific inputs/state -> the wrong
  observable outcome) traced through the diff, plus a file:line pointer. The fix stage will reproduce your scenario,
  fix it, and re-check it - a vague or wrong repro burns a whole stage, so if you cannot state the scenario
  concretely, it is not a mustFix.
- **notes** - judgment calls: a risky pattern, an edge you suspect but could not confirm, a construction likely to
  break under a change the plan implies is coming. One line each: the concern + a pointer. These go to the human in
  the PR's Review notes; do not inflate a note into a mustFix to make it "count".

Write the full findings (what / why it matters / pointer, plus the repro for each mustFix) to a markdown artifact in
the OS temp dir (NOT the repo); return its path as findingsPath. This review costs tokens too: do NOT pad, do NOT
restate the diff, do NOT invent findings to look thorough - empty mustFix and empty notes on a sound diff is a good
and honest result. Style, naming, and simplification are OUT of scope (the human runs /simplify separately).`

const designPrompt = (implProofPath) => `You are a GAME-DESIGN REVIEW of the change proven on this working tree - you judge the shipped behavior as GAMEPLAY,
not as code. You are READ-ONLY: do not modify the tree, do not drive the game, do not write anything into the repo.

Read the plan at ${PLAN} fully - **Objective** and **Design intent** are your rubric - and follow its **Context
references** into the game's design docs where they bear on this change. Then read the implementer's self-proof at
${implProofPath} (in temp) and STUDY its evidence: view every screenshot yourself; for clips, extract and view frames
(e.g. with ffmpeg) rather than trusting captions. Skim \`git diff --stat\` only to know what moved - the diff is not
your subject, the observed behavior is.

Judge what the evidence shows against the Design intent, as a designer would: does it read correctly on screen
(scale, contrast, visual hierarchy)? does the behavior make sense for the player (pacing, feedback, fairness,
affordance)? does anything contradict the game's documented design language? does an edge case produce something
technically correct but wrong as gameplay? Evidence too thin to judge is itself a finding - "no capture shows X, so
the intent cannot be checked" doubles as a proof gap; say it plainly.

Everything you produce is ADVISORY judgment for the human. Return one line per finding in notes (what looks off +
which evidence item or missing capture shows it), with the fuller reasoning in a markdown artifact in the OS temp dir
(NOT the repo); return its path as findingsPath. Do NOT pad or invent findings to look thorough - an empty review of
a change whose evidence matches its intent is a good and honest result.`

const fixPrompt = (adv, implProofPath) => `You are the FIX stage: the adversarial review CONFIRMED defect(s) in the uncommitted change on this working tree,
each with a failure scenario. Fix exactly these - nothing else.
${READS}
The plan is at ${PLAN}; the review's full findings are at ${adv.findingsPath}; the implementer's self-proof is at
${implProofPath} (both in temp). The confirmed defects:
${adv.mustFix.map((f, i) => `${i + 1}. ${f.title}${f.pointer ? ` [${f.pointer}]` : ''}\n   repro: ${f.repro}`).join('\n')}

For each: reproduce or trace the failure scenario FIRST - if it does not actually fail, say so in your summary and
leave that code alone; do not "fix" a non-bug. Then fix it minimally, honoring the plan's **Constraints & decisions**
and **Out of scope**. Do not refactor beyond the fix, and do not touch the review's judgment-grade notes - those are
the human's call.

Then re-prove the tree:
1. Check gate clean: ${G.check}. Iteration tests green: ${G.iter || G.check}.
2. Re-run the FULL gate ONCE - ${G.full} - the implementer's earlier full-gate run no longer covers this tree. Run it
   as ONE synchronous foreground shell call with a generous timeout, output captured to a file.
3. Re-check each defect's failure scenario now behaves correctly - live on the proof surface where the scenario is
   live-reachable, per EVIDENCE.md - and re-run any part of the plan's Validation plan your fix touched, refreshing
   the affected screenshots.
4. Append a "Fix addendum" to the proof artifact at ${implProofPath}: each defect, the fix, and the concrete
   re-checked result (with any refreshed capture paths and one-line captions).

Leave ALL changes UNCOMMITTED - do not commit, push, or write anything into the repo.

Return exactly one outcome:
- "proven": every confirmed defect fixed (or shown not to reproduce, and said so in the summary), gates green,
  re-checks recorded in the Fix addendum.
- "blocked": a defect cannot be fixed without real rework, or the fix would contradict the plan - set blocker naming
  which defect(s) and why. Leave any partial fixes on the tree; the PR will open as a DRAFT carrying your blocker.`

const retroPrompt = (trajectory, implProofPath, reviewArtifacts) => `You are a retrospective on the build pipeline run that just happened - a critical read of how the RUN went, not a
rewrite of the feature. Do NOT touch code, do NOT modify the working tree, do NOT write anything into the repo. You
are read-only.

On a run without reviewers you are the only second pair of eyes on this change before a human reviews the PR; on a
reviewed run the reviewers' findings are raw material for you - audit around them, do not re-litigate them. Your job
is to check the build proceeded as the plan expected and to surface holes - in the plan, in the proof, or in the
process - so the human knows where to look and can improve the build skill (${SKILLDIR}/SKILL.md) or the repo profile
(${PROFILE}). Findings are advisory: they never block the PR.

What this run did, stage by stage:
${trajectory}

Raw material (read all of it):
- the plan: ${PLAN}
- the implementer's self-proof: ${implProofPath} (in temp - do NOT copy it into the repo)
${reviewArtifacts ? `${reviewArtifacts}\n` : ''}- the repo profile at ${PROFILE} (the gates and proof drivers the stages were told to use)
- the shipping diff: run \`git diff\` to see exactly what will land, then cross-check \`git status --porcelain\` - any
  untracked (\`??\`) source file is part of the change that the diff does not show (the worker should have
  \`git add -N\`-ed it; if it didn't, read the file directly and flag the miss as a finding).

Four checks are load-bearing - do them concretely, bullet by bullet, not impressionistically:
1. **Done-when conformance.** Walk the plan's **Done when** and **Executable steps**: does the diff contain the code
   for each item, and does the proof contain evidence for each? An explicitly planned behavior silently missing while
   everything else was green HAS shipped from this pipeline before - it is the single most valuable thing you can
   catch here.
2. **Proof vs diff consistency.** Read the proof's claims against the diff itself: a claim like "docs untouched" while
   the diff edits docs (a false self-report has shipped before), "expected" values that look copied from observed
   output rather than derived from the objective, a scenario that never exercises the paths the diff actually moved,
   an observable behavior left to a unit test that a live scenario could have reached, an interactive surface whose
   human-input-path obligation (EVIDENCE.md's (a)-or-(b)) was never addressed. The implementer graded its own work -
   you are the skeptical reader.
3. **Token & time audit.** Ground this in the run's stage transcripts on disk, not impressions. Locate the run
   directory: glob \`$env:USERPROFILE\\.claude\\projects\\*\\*\\subagents\\workflows\\wf_*\\journal.jsonl\` and pick the
   journal whose text contains this run's proof path above (newest-modified as fallback). Its directory holds one
   \`agent-<id>.jsonl\` transcript per stage; the journal's "result" lines give each completed stage's agentId in
   stage order - analyze exactly those files (this also excludes your own still-growing transcript). The transcripts
   are megabytes: do NOT read them into context - script the aggregation (each line is JSON with a top-level
   \`timestamp\`; assistant lines carry \`message.usage\`, and several lines share one \`requestId\` with a
   progressive count, so a request's output tokens = the MAX \`output_tokens\` per requestId, never the sum of
   lines). Compute per stage: wall-clock (first->last timestamp), total output tokens, tool-call count, and the
   longest tool waits - the gap from a \`tool_use\` line to the next line is that call's execution time; list the
   top ~5 with tool name + a snippet of the command input. Then judge both axes:
   - **Time**: a cold build legitimately takes minutes; a call waiting >10 minutes (a driver verb that never
     answered, a wait that only ended at timeout) is a headline finding - name the command and when it happened.
   - **Tokens**: a stage whose spend is far out of proportion to what it contributed - retry loops re-running the
     same failing command, per-edit full-gate runs the prompts explicitly forbid, a live scenario re-driven from
     scratch after every small fix.
   Include the compact per-stage table (stage | wall-clock | output tokens | tool calls | longest wait) in your
   findings artifact EVEN IF nothing is anomalous - it is the run-over-run trend data the human folds back into the
   skill. If you cannot locate the run directory, say so in the findings instead of skipping silently.
4. **Review-decision audit** (a paragraph, not a stage). The plan's **Review decision** line names which reviewers
   ran and why. Judge that call against what actually shipped: a defect or design miss visible in the diff/evidence
   that a SKIPPED reviewer exists to catch, a reviewer that ran on a change too mechanical to need it, a design
   review hamstrung by a thin or missing **Design intent** section, or an adversarial mustFix whose repro turned out
   vague enough to burn the fix stage. Each is a process finding whose recommendation targets the Step 1 selection
   criteria or the profile's review note - this audit is the feedback loop that keeps conditional review honest.

Beyond those, follow whatever actually looks off in THIS run - a plan hole (an ambiguity the implementer had to guess
through, a constraint the diff quietly contradicts, an Out-of-scope line it crossed), a step that cost tokens without
changing the outcome, a prompt or structural choice in the skill or the profile that steered the agent wrong.
Critical discovery, not checklist coverage.

Write a concise set of findings to an artifact in the OS temp dir (NOT in the repo). For each finding give four
things: what looks off, why it matters, a concrete pointer (which plan bullet / proof claim / diff hunk), and a
**Recommendation** - one specific, actionable change (to the plan template, a prompt in the skill, a line in the
profile, or a follow-up for the human) - not a restated problem. If a finding is genuinely just "worth a look" with no
action you can yet name, say so explicitly rather than inventing a fix. Keep it tight and high-signal - this review
costs tokens too, so do NOT pad or invent findings to look thorough. If the run genuinely looks clean, say so briefly
and stop; a short or near-empty review is a fine and honest result.

Return reviewPath, a 2-3 sentence summary for the run report (the headline of what you surfaced, or that nothing
notable came up), and topFinding - the single most worth-investigating item paired with its recommended action, if any.`

const prPrompt = (implProofPath, reviewPath, reviewNotes, fixedTitles, draftReason) => `Open a PR for the change on the current working tree.
Follow ${SKILLDIR}/PR-FORMAT.md for the branch/commit/PR-body conventions, AND the "PR & publish" section of the repo
profile at ${PROFILE} for this repo's specifics - the architecture-section format and vocabulary, the Try-it command,
the evidence bundle location, and the publish command with its credential source and fallback. Read both first; the
profile wins where they differ. The my-build-full-specific addition below is the Process notes section.
- The plan is at ${PLAN}. The implementer self-proof is at ${implProofPath} and the retrospective findings are at
  ${reviewPath} (both in temp - read them for the body, do NOT copy them into the repo or commit them).
- Branch \`build/${SLUG}\` per PR-FORMAT.md (append -2, -3, ... if taken).
${G.fmt ? `- Fmt before the commit: ${G.fmt}. If it reflows a file outside the logical diff, leave that file out of the commit.\n` : ''}- **Evidence bundle.** Assemble the bundle at the profile's bundle location per PR-FORMAT.md: an \`index.html\`
  telling the validation story claim by claim - the scenario run and the concrete observed results vs what the plan
  predicted, each screenshot/clip from the proof rendered IMMEDIATELY beside the one-line claim it proves (copied in
  from temp, renamed descriptively from its caption), primary behavior first, then each edge the proof reached. (No
  media -> the page is the claim list alone.)
- Stage the source/doc changes with \`git add -A\` scoped to the change - never \`git add -u\`/\`commit -am\`, which
  drop untracked new files - and make ONE commit summarizing the change. Commit NO evidence media and no
  proof/retro \`.md\` artifact; if anything from temp ended up under the repo tree outside the profile's sanctioned
  gitignored homes, it's a mistake; remove it before committing.
- **Sync with the default branch before opening** (per PR-FORMAT.md). If the merge brought in ANY commits - conflicts
  or not - re-run the check gate (${G.check}) plus the touched units' tests: the proof ran against the pre-merge
  tree, and a semantic conflict is invisible to git. If it had textual conflicts, resolve them - preserve both this
  change and the incoming work - then run the full gate instead (${G.full}): the resolution is code no stage has
  tested. The profile's PR & publish section may additionally require re-running live validation - honor it. Merge
  brought in nothing -> nothing to do.
- Open a ${draftReason ? `DRAFT PR (\`gh pr create --draft\`) - unresolved must-fix findings exist: ${draftReason}. Lead the Review notes section with that, verbatim` : 'ready-for-review PR'} against the default branch with \`gh\`. If gh is not authenticated, skip the PR and the
  publish, leave the commit on the branch, and report "PR not opened: gh not authed".
- **Publish the evidence** once the PR number exists, exactly per the profile's publish command and fallback. On
  success, \`gh pr edit\` the review URL into the Validation section. If publishing fails, keep the PR, reference the
  bundle's local path instead, and report the publish error - never block the PR on it.
${TICKET ? `- **Work-queue ticket.** This run ships ticket ${TICKET.id}. After the PR is open and the evidence link is in,
  post the PR URL on the ticket (one line: the URL plus "PR opened by my-build-full"): ${TICKET.note}${draftReason ? `. The PR
  is a DRAFT, so do NOT close the ticket - it stays In Progress until the must-fix findings are resolved; the post-PR
  triage closes it` : `. Then close the ticket: ${TICKET.close}`}. If the PR was not opened (gh not authed), leave the ticket
  untouched. Either way, state the ticket's end state in your return value.
` : ''}- **CI tail** (per PR-FORMAT.md): after the PR is open and the evidence link is in, run \`gh pr checks <number>\`. No
  checks reported -> the repo has no PR CI; move on. Otherwise wait for the checks to conclude (cap the wait at ~15
  minutes); on a failure make AT MOST ONE fix attempt (read the failing log, fix, commit, push, re-check once), then
  stop either way. Fold the final CI state into your return value ("CI green" / "CI red: <reason>" / "CI still
  running after 15m") - a persistently red PR is the human's call, never a reason to loop or close the PR.
- PR body, assembled from the plan + the proof, per PR-FORMAT.md's baseline sections (Objective, Architecture
  changes in the profile's format, Try it from the profile, Validation as link + claim lines) plus:
  - **Review notes (triage before merge)** - ${reviewNotes.length ? `EXACTLY these items, numbered 1..${reviewNotes.length} in this order (the numbering is
    how the human refers to them post-PR; do not reorder, reword, merge, or drop any):
${reviewNotes.map((n, i) => `    ${i + 1}. ${n}`).join('\n')}
    Preface the list with one line: these are judgment findings to triage before merge - addressed on THIS
    branch/PR, or consciously waved through; never a follow-up PR.` : ((REV.adversarial || REV.design) ? 'the reviewers ran and surfaced no judgment findings - say so in one line.' : 'omit this section entirely; the run had no reviewers (per the plan\'s Review decision).')}
${fixedTitles.length ? `  - Add one line at the top of the Validation section: ${fixedTitles.length} defect(s) confirmed by the adversarial
    review were fixed in-run and re-proven (see the proof's Fix addendum): ${fixedTitles.join('; ')}.
` : ''}  - **Process notes (for follow-up)** - inline the contents of the retrospective findings at ${reviewPath} verbatim.
    These are what the run surfaced about the plan and the pipeline itself - plan holes, proof gaps, process leaks -
    for a human to investigate separately and fold back into the skill or profile; leads, not blockers. Do NOT commit
    the artifact; paste its text. If the findings are empty, write "No notable process issues surfaced this run."
Return the PR URL and the CI-tail outcome, or the branch name if gh wasn't authed.`

phase('Implement')
let impl
if (TOTAL === 0) {
  impl = await agent(implPrompt(), { phase: 'Implement', label: 'implement', schema: IMPL_SCHEMA, model: MODEL, ...AG(AGENTS.impl) })
} else {
  // Decomposed build (Step 2b): parallel wave (isolated worktrees) -> merge -> sequential pieces -> integrate-and-prove.
  if (PAR.length > 1) {
    const wave = await parallel(PAR.map((desc, i) => () =>
      agent(parPrompt(i + 1, desc), { phase: 'Implement', label: `impl:par-${i + 1}`, schema: IMPL_SCHEMA, model: MODEL, isolation: 'worktree', ...AG(AGENTS.impl) })))
    const bad = wave.findIndex(r => !r || r.outcome !== 'done')
    if (bad !== -1) {
      const r = wave[bad]
      const trees = wave.filter(Boolean).map(x => x.treePath).filter(Boolean).join(', ')
      const summary = `Parallel piece ${bad + 1}/${PAR.length}: ${r ? r.summary : 'agent returned no result'}. Worktrees left for inspection: ${trees || 'none reported'}`
      if (r && r.outcome === 'cant_prove') return { status: 'cant_prove', missingTooling: r.missingTooling, summary }
      return { status: 'blocked', blocker: r ? r.blocker : 'parallel piece agent died', summary }
    }
    const merge = await agent(mergePrompt(wave), { phase: 'Implement', label: 'merge', schema: IMPL_SCHEMA, model: MODEL, ...AG(AGENTS.light) })
    if (!merge || merge.outcome !== 'done') return { status: 'blocked', blocker: merge ? (merge.blocker || merge.summary) : 'merge agent returned no result', summary: `Merge: ${merge ? merge.summary : 'no result'}` }
  }
  for (let i = 0; i < SEQ.length; i++) {
    const r = await agent(seqPrompt(i + 1, SEQ[i]), { phase: 'Implement', label: `impl:seq-${i + 1}`, schema: IMPL_SCHEMA, model: MODEL, ...AG(AGENTS.impl) })
    if (!r) return { status: 'blocked', blocker: 'piece agent returned no result', summary: `Sequential piece ${i + 1}/${SEQ.length} died` }
    if (r.outcome === 'blocked') return { status: 'blocked', blocker: r.blocker, summary: `Sequential piece ${i + 1}/${SEQ.length}: ${r.summary}` }
    if (r.outcome === 'cant_prove') return { status: 'cant_prove', missingTooling: r.missingTooling, summary: `Sequential piece ${i + 1}/${SEQ.length}: ${r.summary}` }
  }
  impl = await agent(provePrompt(), { phase: 'Implement', label: 'integrate-and-prove', schema: IMPL_SCHEMA, model: MODEL, ...AG(AGENTS.impl) })
}
if (!impl) return { status: 'blocked', blocker: 'implement stage returned no result', summary: '' }
if (impl.outcome === 'blocked') return { status: 'blocked', blocker: impl.blocker, summary: impl.summary }
if (impl.outcome === 'cant_prove') return { status: 'cant_prove', missingTooling: impl.missingTooling, summary: impl.summary }

// Review is conditional per Step 1's review decision - the always-on audit it replaces was removed 2026-07-05
// (31 runs, one real catch, ~29% of a run's output tokens). Reviewers are read-only and artifact-based; only a
// confirmed, repro-backed defect spins up the fix stage. A dead review or a failed fix never kills the run - it
// downgrades the PR to a draft, so the work and the evidence still reach the human.
let adv = null, design = null, fix = null, draftReason = ''
if (REV.adversarial || REV.design) {
  phase('Review')
  const [a, d] = await parallel([
    () => REV.adversarial ? agent(advPrompt(impl.proofPath), { phase: 'Review', label: 'review:adversarial', schema: ADV_SCHEMA, model: MODEL, ...AG(AGENTS.light) }) : null,
    () => REV.design ? agent(designPrompt(impl.proofPath), { phase: 'Review', label: 'review:design', schema: DESIGN_SCHEMA, model: MODEL, ...AG(AGENTS.light) }) : null,
  ])
  adv = a; design = d
  if (REV.adversarial && !adv) draftReason = 'the adversarial review stage died - defect status unknown'
  if (adv && adv.mustFix.length) {
    fix = await agent(fixPrompt(adv, impl.proofPath), { phase: 'Review', label: 'fix', schema: IMPL_SCHEMA, model: MODEL, ...AG(AGENTS.impl) })
    if (!fix || fix.outcome !== 'proven') draftReason = fix ? (fix.blocker || fix.summary) : 'the fix stage died with confirmed defects outstanding'
  }
}
const reviewNotes = [
  ...(adv ? adv.notes.map(n => `[code] ${n}`) : []),
  ...(design ? design.notes.map(n => `[design] ${n}`) : []),
]
const fixedTitles = (fix && fix.outcome === 'proven' && adv) ? adv.mustFix.map(f => f.title) : []

// The Retro still ALWAYS runs; its load-bearing checks are Done-when conformance and proof-vs-diff consistency,
// plus the review-decision audit on reviewed runs.
phase('Retro')
const trajLines = [
  `- Implement: ${impl.outcome}.${TOTAL ? ` (decomposed: ${PAR.length} parallel + ${SEQ.length} sequential pieces, then integrate-and-prove)` : ''} ${impl.summary}`,
]
if (REV.adversarial) trajLines.push(adv ? `- Adversarial review: ${adv.mustFix.length} confirmed defect(s), ${adv.notes.length} judgment note(s). ${adv.summary}` : '- Adversarial review: stage died (no result).')
if (REV.design) trajLines.push(design ? `- Design review: ${design.notes.length} judgment note(s). ${design.summary}` : '- Design review: stage died (no result).')
if (adv && adv.mustFix.length) trajLines.push(fix ? `- Fix: ${fix.outcome}. ${fix.summary}` : '- Fix: stage died (no result).')
const trajectory = trajLines.join('\n')
const reviewArtifacts = [
  adv ? `- the adversarial review findings: ${adv.findingsPath} (in temp)` : null,
  design ? `- the design review findings: ${design.findingsPath} (in temp)` : null,
].filter(Boolean).join('\n')
const retro = await agent(retroPrompt(trajectory, impl.proofPath, reviewArtifacts), { phase: 'Retro', label: 'retro', schema: RETRO_SCHEMA, model: MODEL, ...AG(AGENTS.light) })

phase('PR')
const pr = await agent(prPrompt(impl.proofPath, retro.reviewPath, reviewNotes, fixedTitles, draftReason), { phase: 'PR', label: 'open-pr', model: MODEL, ...AG(AGENTS.light) })
return { status: 'pass', pr, retroFinding: retro.topFinding || '', reviewNotes, fixedDefects: fixedTitles, draft: !!draftReason, draftReason }
```

## Step 2b - Decomposed build (pieces)

Reach here from Step 1's **Decomposition decision**: the work has genuine seams
(per the seam test), or it won't fit one implement-context but folds into
independently-green pieces. Decomposition is a deliberate planning-time call
written into the plan doc - it needs no separate user authorization; the seam test
and the **hard cap of 5 pieces** (the script throws above it) are the guardrails.
It is the *same* Step 2 Workflow, driven by data. Decomposing the *build* is still
**one** PR - never slicing the deliverable.

- **Plan doc**: fill in the **Pieces** section (format in Step 1's section list):
  one line per piece with what it owns and its `needs:` edges.
- **Derive `args.pieces` from the edges**: pieces with no `needs` (and at least
  one sibling like them) -> the `parallel` array; everything else -> `sequential`,
  in dependency order. **Only the first wave parallelizes** - a parallel worktree
  is cut from committed HEAD, so a piece that `needs` another can never run in one
  (it would not see the uncommitted work). If the natural graph has a second
  independent wave, fold it: independent work first, wiring after, or make it
  sequential. A lone dependency-free piece is just the first sequential piece (the
  script normalizes this).
- **Call the same Step 2 script** with the pieces added to `args`.
- **Mechanics**: parallel pieces run concurrently, each in an isolated git
  worktree; a merge step applies each worktree's diff onto the primary tree
  (disjoint footprints make conflicts rare - mostly manifest/lockfiles) and
  removes the merged worktrees; sequential pieces then accumulate UNCOMMITTED on
  the one tree, additive-default so it always passes the check gate; a final
  **integrate-and-prove** stage runs the single full gate plus the plan's live
  Validation plan and writes the proof artifact. **Retro and PR are identical** to
  a single-pass run - the retro reads the whole accumulated diff.
- **Per-piece gate**: exactly the profile's per-piece gate, verbatim - a narrowed
  shortcut once let a real multi-process defect ride latent through three passes.
  No live validation per piece: a piece without its wiring is usually unreachable
  live, and proof-surface startup per piece isn't worth it.
- **Parallelism buys wall-clock only when the per-worktree setup cost is small
  relative to the piece.** Token cost is unchanged, each worktree pays any cold
  build the profile's decomposition note warns about, and the merge step adds a
  little on top. Parallelize only substantial pieces.
- **Failure**: any piece returning `blocked` / `cant_prove` stops the run and
  reports which piece. A failed parallel wave leaves the worktrees in place (paths
  in the report) for inspection; prior sequential work stays uncommitted on the
  tree.

## After the pipeline

When the Workflow completes, report compactly based on its return value:

- `status: pass` -> the PR URL and its CI-tail state (or branch name if `gh`
  wasn't authed), and whether it opened as a **DRAFT** (`draft: true`) - if so,
  lead with `draftReason`: unresolved must-fix findings are the first thing the
  human must look at. Relay the work-queue ticket's end state when the run
  carried one (closed, or left In Progress - the PR stage's return names it).
  Then run the **post-PR triage** below.
- `status: blocked` -> no PR; the implementer hit a blocker it wouldn't guess
  past. Quote `blocker` so the user can resolve the ambiguity or fix the plan. A
  decomposed run's summary names the failing piece (and, for a parallel wave, the
  worktree paths left for inspection) - relay that too.
- `status: cant_prove` -> no PR; quote `missingTooling` and ask whether to build
  that validation surface next.

Don't poll or babysit while it runs; you're notified when it finishes.

## Post-PR triage (the human's review pass)

The PR arriving is not the end of the workflow: applying review to the PR before
merge is the norm; slam-merging a clean run is the exception. Keep the firing
session lean - relay compactly from the return value, spawn fresh subagents for
any follow-up work, and never read the findings artifacts, the proof, or the PR
diff into the main context.

1. **Relay the triage list.** Print `reviewNotes` verbatim, numbered exactly as
   returned (the numbering matches the PR's Review notes section), `fixedDefects`
   in one line ("fixed in-run: ..."), and `retroFinding` with a pointer to the
   PR's Process notes for the rest. Empty everything -> say the run came back
   clean and the PR is ready for the human's own read.
2. **The human picks** which notes to address (by number), which to consciously
   skip, plus anything from their own read of the PR. Do not pre-filter, rank, or
   advocate - the worth-addressing judgment is precisely the part of this
   workflow that stays human. Wait for their reply; there is nothing to do
   proactively here.
3. **Address on the SAME branch/PR - never a follow-up PR.** On selection, spawn
   ONE fresh subagent (Agent tool; the profile's impl worker type if it names
   one) seeded with: the PR number and branch, the selected note texts verbatim,
   the plan path, and the profile + EVIDENCE.md paths. Its instructions: make the
   selected changes on the PR branch, honoring the plan's Constraints & decisions;
   run the check gate and iteration tests, plus the full gate once if the change
   is more than trivial; re-prove live any proof claim it touched and refresh the
   affected evidence; if media changed, rebuild the evidence bundle and re-publish
   per the profile (fresh immutable URL -> `gh pr edit` it in); push to the same
   branch; comment on the PR naming which numbered items it addressed. Relay its
   report in a sentence or two. Repeat as the human asks for more rounds.
4. **Process notes are a different lane.** Retro findings are edits to this skill
   or the repo profile, not to the branch - handle them in-session with the human
   when they take one up, or leave them as leads.
5. **Merging stays the human's call.** Never merge, close, or mark the draft
   ready yourself - a draft PR converts only after its must-fix findings are
   resolved on the branch.
6. **Ticket close-out.** A draft PR (or an unauthed-gh run) leaves the run's
   work-queue ticket In Progress. When the human marks the PR ready after fixes
   (or the PR finally opens), close the ticket with the profile's Work queue
   close verb - one command, run it directly. A ready PR's ticket was already
   closed by the PR stage; nothing to do.
