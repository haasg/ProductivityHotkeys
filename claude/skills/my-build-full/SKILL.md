---
name: my-build-full
description: Distill the current conversation's aligned plan into a lean executable doc, then run an autonomous Workflow - implement-and-self-prove -> plan-selected read-only reviewers (adversarial code / game-design), each returning a fix lane that lands in-run and escalated notes for the human -> a read-only retrospective that checks the build ran as the plan expected -> open a PR carrying per-review findings (numbered A1../D1../R1..) and, on a full retro, a token & time audit - using fresh-context subagents. The plan's Scope & risk call scales the ceremony to the task: evidence full (curated published bundle) or light (the proof artifact published as-is, linked from the PR), retro full or light (Done-when + proof-vs-diff is the floor); proof itself never scales down. Ends with a post-PR triage step: the human picks which findings to address and a fresh subagent applies them on the same branch/PR. Repo-specific gates, proof surface, and publish mechanics come from the repo's skill profile. Stops and asks if a change is blocked or can't be proven without tooling that doesn't exist yet. Use after a grilling/planning session when you want to go from alignment to a reviewable PR without babysitting.
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
        |                    |         |           holes and proof gaps (the LIGHT floor); a FULL retro adds
        |                    |         |           the token/time audit and judges the review + scope calls
        |                    |         |           -> a Retro findings section (R1..) in the PR, plus the
        |                    |         |              audit table on a full retro (advisory, never blocks)
        |                    |         |
        |                    |         +- whenever EITHER reviewer returned fix items: verify each, land
        |                    |            exactly those, re-gate, re-prove -> the fixes ship INSIDE the
        |                    |            PR; an unlanded defect/violation -> the PR opens as a DRAFT
        |                    |
        |                    +- 0-2 read-only reviewers, picked at plan time per task shape (Step 1's
        |                       review decision): adversarial code review (defect hunt) and/or
        |                       game-design review of the proof evidence (design-intent judgment).
        |                       Each returns TWO lanes - `fix` (exact changes, landed in-run) and
        |                       `notes` (escalated findings for the human, A1../D1.. in the PR);
        |                       mechanical changes get neither reviewer
        |
        +- one agent by default; a decomposed plan (Step 2b) runs it as <=10 piece agents:
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
empty review of a sound change is a good and honest result.

**Ceremony scales to the task, the same way review does.** The plan's **Scope &
risk** section states the scope/risk call in one sentence and sets two knobs from
it independently. **Light evidence** skips the curated bundle, never the publish:
the proof artifact itself is published as a minimal page and the PR's Validation
section links it - at either setting that section is one clickable link, never a
copied claim list. **Light retro** keeps Done-when conformance and
proof-vs-diff consistency and drops the token & time audit and the review-decision
audit. Full/full is the default and the in-doubt answer; anything player-visible
moved forces evidence FULL, and so does a selected design review (it judges the
bundle). What never scales down is the **proof**: the implementer drives the
scenario live and captures the screenshots and clips EVIDENCE.md demands on every
run, at every size. Light trims what gets ceremonially packaged, never what gets
verified.

**Both reviewers sort what they find into two lanes: `fix` and `notes` - and they
fix by default.** A finding lands in-run, inside the PR, unless it genuinely needs
a human: it picks among real alternatives, moves the plan's constraints or a public
surface, is too big or risky for one fix pass, or the reviewer isn't confident it's
even an improvement. The fix lane demands **exactness** - the reviewer states the
precise change, because the fix stage executes instructions and never interprets
directions. Everything escalated rides to the PR as that lane's numbered findings
(`A1..` adversarial, `D1..` design, `R1..` retro) for the human to triage after the
PR opens - addressed on the same branch/PR, never a follow-up PR. Escalation is
held to an **impact bar**: surface a finding only when its impact justifies a
human's review time; few or none is a good honest result.

The **Retro** phase reads the run rather than writing the feature - on a run with
no reviewers it is the only second pair of eyes before the human. A fresh
read-only agent takes the plan, the implementer's outcome + proof artifact, the
reviewers' findings (when they ran), and the shipping diff, and **checks the
build proceeded as the plan expected**: every Done-when bullet has matching code
in the diff and evidence in the proof, the proof's claims are consistent with the
diff, the validation actually exercised the paths the diff moved, and the plan
itself held up. That much is the **floor** - it runs at both depths. A **full**
retro adds two lanes on top: it audits the run's **efficiency** from the stage
transcripts on disk, and - the meta-review lane - judges whether Step 1's
**review decision** and the plan's **Scope & risk** picks were right for what
actually shipped. Each finding carries a **concrete recommendation**. The findings
land in the PR as its own **Retro** section (`R1..`), with the per-stage **token &
time audit** table beside it on a full retro, as leads for you to investigate
separately. It is **advisory and read-only** - it never blocks the PR and never
changes code - and it never disappears: light is the floor, not off.

You fire one command and walk away; you come back to a PR - with per-review
findings to triage, and the token & time audit attached on a full retro - or to a
clear report (blocked, or it can't be proven without new tooling you should decide
on). The PR is not the finish line: the norm is the **post-PR triage step** (see
After the pipeline) where the human picks which escalated findings to address, a
fresh subagent applies them on the same branch/PR, and only then it merges -
slam-merging a clean run is the exception, not the habit. Every stage is a
**fresh-context subagent seeded only by the plan doc + the working-tree diff + the
implementer's proof** - never the grilling transcript, and never a resumed agent.
The implementer's work persists on the working tree, so each later stage just
reads the diff off disk - and the post-PR follow-up stays on subagents too, so the
firing session's context never absorbs the diff or the findings artifacts.

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
even when the conversation looks fully aligned. One equivalent to an explicit
invocation: a grill whose final round offered the `go` shortcut and got `go` back -
the user authorized this launch in writing, in advance, so working these steps then
is not a proactive fire.

After grilling/planning, when alignment is high and you want a reviewable PR -
with a process retrospective attached - without babysitting. Standalone - does not
require a grill to have run; it distills whatever alignment exists in the current
conversation. If the conversation has little concrete alignment (especially no
validation strategy - see Step 1), say so plainly but still proceed if asked.

The pipeline ships the implementer's diff hardened by exactly the fix items the
reviewers listed - it does **not** sweep the change for simplification. Reviewers
are not style hunters: they land a clearly-agreeable naming or simplification item
noticed *in passing*, but they hunt defects and judge design intent. To sweep the
diff deliberately, run `/simplify` or `/code-review` by hand on the branch after
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

**Scope & risk - carry it over, or make the call here.** A grill that ran its
sizing step already stated the scope/risk assessment and pinned the two pipeline
knobs; copy that statement and those picks into the plan's **Scope & risk**
section. When the conversation carries no assessment (a standalone build-full, or a
grill that never sized), make the call yourself from what the change touches. Two
knobs, one line of rationale each:

- `evidence: full|light` - full assembles and publishes the curated evidence
  bundle; light publishes the proof artifact as-is and the PR links that page.
  Both publish, and both PR Validation sections are a single clickable link. **FULL
  whenever anything player-visible moved**, and full whenever a design review is
  selected - that reviewer's whole subject is the evidence. (The script forces
  that second case and reports the override loudly, but don't lean on the guard;
  pick it right.)
- `retro: full|light` - light keeps Done-when conformance and proof-vs-diff
  consistency; full adds the token & time audit and the review/scope-decision
  audit.

**In doubt -> full/full.** Light is a claim that this run is small AND
unsurprising, so it is the claim the full retro checks back on. Pass both as Step
2's `evidence` / `retro` args, and record the reasoning in the plan, not just the
picks. Neither knob touches the proving: the implementer still self-proves live per
EVIDENCE.md on a light run.

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
  10-piece cap are the guardrails.
- **Too big even decomposed - STOP. Do not launch.** If the objective will not
  fold into **at most 10** each-independently-green pieces, it does not belong in
  one PR (the script throws above 10 - never hand it an 11-piece plan and let it
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
  every confirmed one with a concrete failure scenario. Skip it for
  straightforward wiring and content work.
- **Game-design review** - enlist when the change moves player-facing behavior,
  feel, or visuals. It judges the proof evidence against the plan's **Design
  intent** as gameplay rather than code - and therefore requires that section to
  be written. Skip it when nothing a player experiences changes.
- **Neither** - the default for mechanical/content-only changes (asset swaps,
  renames, config, doc moves): the retro alone is the second read.

Both reviewers carry the same two lanes: an exactly-stated `fix` item lands in-run
before the PR, and only a finding that genuinely needs a human's call escalates to
that lane's PR findings (see the fix-by-default rule above).

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
- **Scope & risk** - *always.* The one-sentence scope/risk assessment (carried
  over from the grill, or made here), then the two picks on their own lines -
  `evidence: full|light` and `retro: full|light` - each with one line of
  rationale. A full retro reads this section to judge whether the picks matched
  what actually shipped, so the rationale is the part that matters.
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
  evidence: "<full|light>",
  retro: "<full|light>",
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

`evidence` and `retro` carry the plan's **Scope & risk** picks; the script defaults
each to `'full'` when the key is absent or anything other than `'light'`. One
script-level guard: when `reviews.design` is true, evidence is forced to FULL
regardless of the arg - the design reviewer judges the evidence bundle, so there
has to be one. The override is reported in the retro's trajectory and in the run's
return value (`evidenceForced`) so it can never pass silently.

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
  description: 'Implement and self-prove an aligned plan doc, review it per the plan\'s review decision (landing each reviewer\'s fix lane in-run), retro the run, open a PR',
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
// Scope & risk knobs (the plan's Scope & risk section): ceremony scales to the task, proof never does. Default full.
const EVID_ARG = A.evidence === 'light' ? 'light' : 'full'
// Guard: a design review's whole subject is the evidence bundle, so a design-reviewed run gets FULL evidence whatever
// the arg said. Surfaced in the retro trajectory and the return value below - an override here is never silent.
const EVIDENCE = (EVID_ARG === 'light' && REV.design) ? 'full' : EVID_ARG
const EVID_FORCED = EVIDENCE !== EVID_ARG
const RETRO_DEPTH = A.retro === 'light' ? 'light' : 'full'
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
if (TOTAL > 10) throw new Error('my-build-full: decomposed build is capped at 10 pieces - if the seams yield more, the objective is too big for one PR; rescope with the user (see Step 2b).')

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

// Both reviewers return the same two lanes: `fix` (exact changes the fix stage lands in-run) and `notes` (escalated
// findings the human triages on the PR). NOTES_SCHEMA is that escalation lane; the retro's findings use it too.
const NOTES_SCHEMA = (what) => ({
  type: 'array',
  description: `${what} - ordered highest impact first, no cap. Surface a finding ONLY when its impact justifies a human's review time; few or none is a good honest result. Never surface a low-impact item just to have something to show.`,
  items: {
    type: 'object',
    required: ['issue', 'recommendation'],
    additionalProperties: false,
    properties: {
      issue: { type: 'string', description: 'the finding, concisely, with its concrete pointer (file:line, evidence item, plan bullet)' },
      recommendation: { type: 'string', description: 'the recommended solution - specific and actionable, not a restated problem' },
    },
  },
})

const ADV_SCHEMA = {
  type: 'object',
  required: ['summary', 'findingsPath', 'fix', 'notes'],
  additionalProperties: false,
  properties: {
    summary: { type: 'string', description: '1-2 sentences: the headline, or that the diff looks sound' },
    findingsPath: { type: 'string', description: 'path to the full findings markdown in temp' },
    fix: {
      type: 'array',
      description: 'items the fix stage lands in-run - fix by default, escalate to notes by exception. Each states the EXACT change to make; a defect also carries the failure scenario the fix stage re-checks.',
      items: {
        type: 'object',
        required: ['title', 'kind', 'change'],
        additionalProperties: false,
        properties: {
          title: { type: 'string', description: 'one line naming the item; the fix stage reports back by this exact title' },
          kind: { enum: ['defect', 'improvement'] },
          change: { type: 'string', description: 'the precise change to make, executable without interpretation (e.g. "clamp N to the band height at panel.rs:88")' },
          pointer: { type: 'string', description: 'file:line or diff hunk' },
          repro: { type: 'string', description: 'defects only: the concrete failure scenario - specific inputs/state -> the wrong observable outcome, traced through the diff' },
        },
      },
    },
    notes: NOTES_SCHEMA('escalated code findings for the PR\'s Adversarial section (A1..)'),
  },
}

const DESIGN_SCHEMA = {
  type: 'object',
  required: ['summary', 'findingsPath', 'fix', 'notes'],
  additionalProperties: false,
  properties: {
    summary: { type: 'string', description: '1-2 sentences: the headline, or that the evidence matches the design intent' },
    findingsPath: { type: 'string', description: 'path to the full findings markdown in temp' },
    fix: {
      type: 'array',
      description: 'items the fix stage lands in-run - fix by default, escalate to notes by exception. Each states the EXACT change to make; a violation also carries the evidence item that shows it.',
      items: {
        type: 'object',
        required: ['title', 'kind', 'change'],
        additionalProperties: false,
        properties: {
          title: { type: 'string', description: 'one line naming the item; the fix stage reports back by this exact title' },
          kind: { enum: ['violation', 'improvement'] },
          change: { type: 'string', description: 'the precise change to make, executable without interpretation (e.g. "raise the label to 12px at hud.rs:44")' },
          pointer: { type: 'string', description: 'file:line, or the evidence item that shows it' },
          evidence: { type: 'string', description: 'violations only: the concrete evidence pointer - which screenshot/clip/frame shows the design intent being violated' },
        },
      },
    },
    notes: NOTES_SCHEMA('escalated design findings for the PR\'s Design section (D1..)'),
  },
}

// The fix stage's own shape: which listed items landed, which were dismissed as not real, which were demoted to PR
// findings. Only an unlanded item of kind defect/violation drafts the PR (see the draft logic below).
const FIX_SCHEMA = {
  type: 'object',
  required: ['outcome', 'summary', 'landed', 'dismissed', 'demoted'],
  additionalProperties: false,
  properties: {
    outcome: { enum: ['proven', 'blocked'] },
    summary: { type: 'string', description: 'one paragraph: what landed, what did not, and how the gates were met' },
    landed: { type: 'array', items: { type: 'string' }, description: 'titles (verbatim, as listed to you) of the items that were applied AND re-checked' },
    dismissed: {
      type: 'array',
      description: 'items verified NOT to be real - the repro did not fail, or the described state does not match the code. Nothing was changed for these.',
      items: {
        type: 'object',
        required: ['title', 'reason'],
        additionalProperties: false,
        properties: {
          title: { type: 'string', description: 'the item title, verbatim' },
          reason: { type: 'string', description: 'one line: what you checked and what it actually does' },
        },
      },
    },
    demoted: {
      type: 'array',
      description: 'real items NOT landed - each demoted to a PR finding rather than churned (it ballooned beyond its description, cascades, needs rework, or touches design intent)',
      items: {
        type: 'object',
        required: ['title', 'reason'],
        additionalProperties: false,
        properties: {
          title: { type: 'string', description: 'the item title, verbatim' },
          reason: { type: 'string', description: 'one line: why it was not landed' },
        },
      },
    },
    blocker: { type: 'string', description: 'blocked only: why the stage could not finish (gates left red, tree left mid-fix)' },
  },
}

// The retro's shape follows its depth (the plan's Scope & risk `retro` pick). A light retro runs the Done-when and
// proof-vs-diff checks only - it never scrapes a transcript, so it has no audit table to return and the field is
// absent from its schema entirely rather than being an optional it might invent a value for.
const RETRO_PROPS = {
  summary: { type: 'string', description: '2-3 sentences for the run report: the headline of what was surfaced, or that nothing notable came up' },
  reviewPath: { type: 'string', description: 'path to the full findings markdown in temp (the fuller reasoning; the PR renders the structured fields below, not this file)' },
  findings: NOTES_SCHEMA('run findings for the PR\'s Retro section (R1..)'),
  topFinding: { type: 'string', description: 'the single most worth-investigating item, if any - paired with its recommended action' },
}
const RETRO_SCHEMA_LIGHT = {
  type: 'object',
  required: ['summary', 'reviewPath', 'findings'],
  additionalProperties: false,
  properties: RETRO_PROPS,
}
const RETRO_SCHEMA_FULL = {
  type: 'object',
  required: ['summary', 'reviewPath', 'findings', 'auditTable'],
  additionalProperties: false,
  properties: {
    ...RETRO_PROPS,
    auditTable: { type: 'string', description: 'the token & time audit as a markdown table (stage | wall-clock | output tokens | tool calls | longest wait) - required on a FULL retro, even when nothing is anomalous; it is the run-over-run trend data' },
    auditNote: { type: 'string', description: 'optional, and ONLY when something anomalous happened (a >10min tool wait, a stage wildly out of proportion) or the run directory could not be located - concise even then' },
  },
}
const RETRO_SCHEMA = RETRO_DEPTH === 'light' ? RETRO_SCHEMA_LIGHT : RETRO_SCHEMA_FULL

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
   names). OPEN the artifact with the At-a-glance section EVIDENCE.md requires - the problem in plain language,
   before, and after, each beside its single most convincing capture - then the full detail below it. List each
   screenshot's absolute path and a one-line caption of what it shows (these become the published evidence page).
   Return the artifact path as proofPath.

Leave ALL source changes UNCOMMITTED on the working tree - do not commit, push, or write a report into the repo.

Return exactly one outcome:
- "proven": implemented; check gate and full gate green; the Validation plan scenario ran and matched. Set proofPath.
- "cant_prove": proving it would need validation tooling that does not exist yet - do NOT build it. Set missingTooling.
- "blocked": a verify step is impossible, the plan is ambiguous or contradicts a documented decision, or you cannot
  reach green (including: the profile's proof-surface readiness check fails and its Proof surface section says that
  is a blocker). Set blocker to the specific reason. Do NOT guess, fake success, or claim "proven" without running
  the scenario.
${NOTES ? `\nExtra notes: ${NOTES}` : ''}`

// Decomposed build (Step 2b): <=10 pieces on real seams, each sized to fit one impl agent's context. The parallel
// wave is the dependency-free pieces, each in an isolated worktree cut from committed HEAD - which is exactly why
// only dependency-free pieces may parallelize: a worktree cannot see other pieces' uncommitted work. A merge step
// applies their diffs onto the primary tree; the sequential pieces then accumulate on it. Pieces gate on the
// profile's per-piece gate; only the integrate-and-prove stage runs live validation + the single full gate and
// writes the proof artifact the retro/PR read.

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
   \`build-${SLUG}-impl\` under \`$env:TEMP\` / \`%TEMP%\`, copying your screenshots in; OPEN it with the At-a-glance
   section EVIDENCE.md requires (problem in plain language, before, after - each beside its single most convincing
   capture), then the full detail; list each screenshot's absolute path and a one-line caption (these become the
   published evidence page). Return that path as proofPath.

Leave ALL changes UNCOMMITTED - do not commit, push, or write a report into the repo.

Return exactly one outcome:
- "proven": check gate clean; the full gate green; the Validation plan scenario ran LIVE and matched. Set proofPath.
- "cant_prove": proving it would need validation tooling that does not exist yet - do NOT build it. Set missingTooling.
- "blocked": you cannot reach green, or the accumulated diff needs real rework. Set blocker. Do NOT guess or fake success.
${NOTES ? `\nExtra notes: ${NOTES}` : ''}`

// The fix-vs-notes sorting rule, identical for both reviewers: fix by default, escalate only by exception, and an
// escalated finding must clear the impact bar (the human's review time is the pipeline's scarcest resource).
const LANES = `Sort what survives into exactly two lanes - and **fix by default**. For each finding, ask: would a
reasonable human plausibly want this done differently, or not done at all? If not, it goes in \`fix\` and lands in-run.

- **fix** - the fix stage applies exactly these before the PR opens. **Exactness is the entry fee**: state the precise
  change ("clamp N to the band height at \`panel.rs:88\`"), never a direction ("make the clamping more robust") - the
  fix stage EXECUTES instructions and never interprets them. Worth doing but not pin-downable that precisely -> that
  fact alone escalates it. What belongs here once it clears the bar: confirmed defects/violations, preventive
  hardening (not broken today, breaks under an obvious near-term change, cheap guard), and a style, naming, or
  simplification item you noticed IN PASSING that is clearly agreeable.
- **notes** - escalated to the human, numbered on the PR for triage. Escalate ONLY when one of these holds: (a) it
  requires choosing among genuinely different alternatives, or it moves the plan's constraints, the design intent, or
  a public surface; (b) it is too big or too risky to land safely in one fix pass; or (c) you are not confident it is
  actually an improvement (a suspicion, a taste call). Each note is an issue + a recommended solution, ordered
  highest impact first, with no cap on the count.

**Impact bar for notes:** surface a finding only when its impact justifies a human's review time - a low-impact
suggestion spawns a sub-task nobody ever gets to, which is worse than silence. Few or none is a good, honest result;
never surface something just to have something to show.`

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

${LANES}
Lane specifics for this review: a \`fix\` item of kind **defect** also needs its concrete failure scenario as
\`repro\` (specific inputs/state -> the wrong observable outcome, traced through the diff) - the fix stage
reproduces it, fixes it, and re-checks it, so a vague or wrong repro burns a whole stage. Everything else you land is
kind **improvement** and needs no repro, just the exact \`change\`. A suspicion you could not confirm is never a
defect: it is a note, or it is nothing.

Write the full findings (what / why it matters / pointer, plus the repro for each defect) to a markdown artifact in
the OS temp dir (NOT the repo); return its path as findingsPath. This review costs tokens too: do NOT pad, do NOT
restate the diff, do NOT invent findings to look thorough - empty fix and empty notes on a sound diff is a good and
honest result. You are not a style hunter: your mission is defect hunting, and \`/simplify\` is the deliberate
style/simplification sweep the human runs separately - which is exactly why only an in-passing, clearly-agreeable
cleanup rides along in your fix lane.`

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
the intent cannot be checked" doubles as a proof gap; say it plainly. **Clip duration is part of that check**:
EVIDENCE.md requires a clip to cover the full scenario (steady lead-in, the behavior, the settled end state) at
real-time speed with a 5-second minimum - a clip under that floor, or one too short for you to judge the motion it
exists to show, is a finding in its own right; say which clip and how long it actually is.

${LANES}
Lane specifics for this review: a \`fix\` item of kind **violation** also needs \`evidence\` - the concrete pointer
(which screenshot, clip, or frame) that shows the Design intent being violated. Everything else you land is kind
**improvement** and needs only the exact \`change\`. You judge behavior, but a fix item is still a code instruction:
if you cannot name the precise change to make, it escalates to notes. A missing or unjudgeable capture is always a
note (nobody can fix it from your seat) - the fix stage cannot re-drive the game.

Write the fuller reasoning to a markdown artifact in the OS temp dir (NOT the repo); return its path as findingsPath.
Do NOT pad or invent findings to look thorough - an empty review of a change whose evidence matches its intent is a
good and honest result.`

const fixPrompt = (items, artifacts, implProofPath) => `You are the FIX stage: the review lane(s) that ran handed you ${items.length} item(s) to land in the uncommitted
change on this working tree. Apply exactly these - nothing else, nothing self-initiated.
${READS}
The plan is at ${PLAN}; the implementer's self-proof is at ${implProofPath}; the reviewers' full findings are at:
${artifacts}
The items to land, each with the exact change its reviewer specified:
${items.map((f, i) => `${i + 1}. [${f.lane}/${f.kind}] ${f.title}${f.pointer ? ` [${f.pointer}]` : ''}\n   change: ${f.change}${f.repro ? `\n   repro: ${f.repro}` : ''}${f.evidence ? `\n   evidence: ${f.evidence}` : ''}`).join('\n')}

**Verify before you touch anything.** For a defect, reproduce or trace its repro FIRST; for a violation or an
improvement, confirm the current code actually matches the description it is premised on. If it does not hold, that
item is DISMISSED: change nothing for it, and report it in \`dismissed\` with one line of what the code actually does.
Never "fix" a non-bug.

Then apply each surviving item as the change states it - minimally, honoring the plan's **Constraints & decisions**
and **Out of scope**. You EXECUTE these instructions; you do not reinterpret them into something you would rather do.
Land the listed items ONLY: no refactoring beyond them, no acting on the reviewers' escalated notes (those are the
human's call after the PR opens), no improvements of your own.

**Demotion valve - do not churn.** If an item balloons beyond its description (it cascades into unrelated code, needs
real rework, or turns out to move design intent or a public surface), stop work on it, revert what you started for it,
and report it in \`demoted\` with a one-line reason. It becomes a finding on the PR instead. Demoting one item is
normal and cheap; a half-landed item is not.

Then re-prove the tree:
1. Check gate clean: ${G.check}. Iteration tests green: ${G.iter || G.check}.
2. Re-run the FULL gate ONCE - ${G.full} - the implementer's earlier full-gate run no longer covers this tree. Run it
   as ONE synchronous foreground shell call with a generous timeout, output captured to a file.
3. Re-check each LANDED item concretely: a defect's failure scenario now behaves correctly, a violation's evidence
   pointer now shows the intended thing - live on the proof surface wherever that is live-reachable, per EVIDENCE.md -
   and re-run any part of the plan's Validation plan your changes touched, refreshing the affected screenshots and
   clips (a refreshed clip still owes EVIDENCE.md's full-scenario, 5-second-floor rule).
4. Append a "Fix addendum" to the proof artifact at ${implProofPath}: every item, what you did with it (landed /
   dismissed / demoted, with the reason), and the concrete re-checked result - including any refreshed capture paths
   with one-line captions. If a refreshed capture replaces one the proof's At-a-glance section leads with, update
   that reference in place - the top section must keep showing the current behavior.

Leave ALL changes UNCOMMITTED - do not commit, push, or write anything into the repo.

Account for every item exactly once across \`landed\`, \`dismissed\`, and \`demoted\`, using each item's title
VERBATIM as listed above - the PR's per-review sections are assembled from those titles.

Return exactly one outcome:
- "proven": every item is accounted for, the gates are green, and the re-checks are in the Fix addendum. Dismissals
  and demotions are a normal part of a "proven" run - they are reported, not blockers.
- "blocked": you cannot get the tree back to green, or you had to leave it mid-fix - set blocker with the specifics.
  Leave the partial work on the tree; the PR will open as a DRAFT carrying your blocker.`

// A FULL retro's two extra checks (the plan's Scope & risk `retro` pick). Light drops both - no transcript scraping at
// all, and no meta-review of the run's own decisions; checks 1 and 2 are the floor and run at both depths.
const CHECK_EFFICIENCY = `3. **Token & time audit.** Ground this in the run's stage transcripts on disk, not impressions. Locate the run
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
   Return the compact per-stage table (stage | wall-clock | output tokens | tool calls | longest wait) as
   \`auditTable\` - a markdown table, even when nothing is anomalous: it is the run-over-run trend data the
   human folds back into the skill, and it gets its own section in the PR. Set \`auditNote\` ONLY when something
   anomalous actually happened (name the command and when), or to say you could not locate the run directory - and be
   concise even then. Anything worth the human's action is a finding, not a note.`

const CHECK_DECISIONS = `4. **Review- and scope-decision audit** (a paragraph, not a stage). The plan's **Review decision** line names which
   reviewers ran and why. Judge that call against what actually shipped: a defect or design miss visible in the
   diff/evidence that a SKIPPED reviewer exists to catch, a reviewer that ran on a change too mechanical to need it, a
   design review hamstrung by a thin or missing **Design intent** section, or a fix-lane item whose stated change
   turned out vague or wrong enough to burn the fix stage. Each is a process finding whose recommendation targets the
   Step 1 selection criteria or the profile's review note - this audit is the feedback loop that keeps conditional
   review honest. If your verdict DISAGREES with the plan's pick, make that an explicit finding (the PR notes the
   disagreement on its Reviews line).
   Then judge the plan's **Scope & risk** picks the same way, on the same evidence: was \`evidence: light\` right for a
   run that turned out player-visible or subtle (a light pick there means only the raw proof page was published, not
   the curated claim-by-claim bundle a design read wants), and was \`retro: light\` right for a run whose diff or
   proof turned out to want the deeper read? A wrong pick
   is a finding whose recommendation targets the sizing criteria - the grill's sizing step or Step 1's Scope & risk
   guidance - exactly like a wrong review pick.`

// The audit table is owed on a full retro even when the findings list comes back empty; a light retro owes no table.
const AUDIT_OWED = RETRO_DEPTH === 'light' ? '' : ' (the `auditTable` is still owed)'

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

${RETRO_DEPTH === 'light' ? `This is a **LIGHT** retro: the plan's **Scope & risk** section picked \`retro: light\` for a small, unsurprising run.
The token & time audit and the decision audit are deliberately NOT part of it - do NOT locate the run directory, do NOT
open any stage transcript, and return no audit table (your schema has no such field). Light is this pipeline's FLOOR,
not a skip: the two checks below are exactly as load-bearing here as on a full retro.

Two checks are` : `Four checks are`} load-bearing - do them concretely, bullet by bullet, not impressionistically:
1. **Done-when conformance.** Walk the plan's **Done when** and **Executable steps**: does the diff contain the code
   for each item, and does the proof contain evidence for each? An explicitly planned behavior silently missing while
   everything else was green HAS shipped from this pipeline before - it is the single most valuable thing you can
   catch here.
2. **Proof vs diff consistency.** Read the proof's claims against the diff itself: a claim like "docs untouched" while
   the diff edits docs (a false self-report has shipped before), "expected" values that look copied from observed
   output rather than derived from the objective, a scenario that never exercises the paths the diff actually moved,
   an observable behavior left to a unit test that a live scenario could have reached, an interactive surface whose
   human-input-path obligation (EVIDENCE.md's (a)-or-(b)) was never addressed. The implementer graded its own work -
   you are the skeptical reader. **Check the clips as artifacts, not just as claims**: EVIDENCE.md requires a
   recording to cover the full scenario (steady lead-in, the behavior, the settled end state) at real-time speed with
   a 5-second minimum floor - read each clip's actual duration off disk (e.g. \`ffprobe\`), and flag any clip under
   the floor or too short to judge the motion it exists to show as a finding, naming the file and its real duration.
${RETRO_DEPTH === 'light' ? '\n' : `${CHECK_EFFICIENCY}\n${CHECK_DECISIONS}\n\n`}Beyond those, follow whatever actually looks off in THIS run - a plan hole (an ambiguity the implementer had to guess
through, a constraint the diff quietly contradicts, an Out-of-scope line it crossed), a step that cost tokens without
changing the outcome, a prompt or structural choice in the skill or the profile that steered the agent wrong.
Critical discovery, not checklist coverage.

Write the fuller reasoning to an artifact in the OS temp dir (NOT in the repo) and return its path as reviewPath: for
each finding, what looks off, why it matters, and its concrete pointer (which plan bullet / proof claim / diff hunk /
transcript line). Then return the findings themselves in \`findings\` - the PR renders THOSE, not your artifact, one
numbered R-item each: \`issue\` (the finding plus its pointer, concisely) and \`recommendation\` (one specific,
actionable change - to the plan template, a prompt in the skill, a line in the profile, or a follow-up for the human -
never a restated problem).

**Findings are held to an impact bar:** surface one only when its impact justifies a human's review time. A
low-impact suggestion spawns a sub-task nobody ever gets to, which is worse than silence - so do NOT pad, do NOT
invent findings to look thorough, and never surface something just to have something to show. Few or none is a good,
honest result; if the run genuinely looks clean, return an empty \`findings\`${AUDIT_OWED} and
say so in the summary. If a finding is genuinely just "worth a look" with no action you can yet name, say that
plainly in its recommendation rather than inventing a fix.

Also return: a 2-3 sentence summary for the run report (the headline of what you surfaced, or that nothing notable
came up), and topFinding - the single most worth-investigating item paired with its recommended action, if any.`

// Fix-lane bookkeeping, shared by the draft decision and the PR body. Items are matched back to the reviewer that
// raised them by their VERBATIM title - which is why the fix stage is told to echo titles exactly.
const itemByTitle = (items, title) => items.filter(i => i.title === title)[0] || null
const fixLine = (lane, fixResult, items) => {
  if (!fixResult) return ''
  const mine = (title) => { const it = itemByTitle(items, title); return !!it && it.lane === lane }
  const landed = fixResult.landed.filter(mine)
  const demoted = fixResult.demoted.filter(d => mine(d.title))
  const dismissed = fixResult.dismissed.filter(d => mine(d.title))
  const parts = []
  if (landed.length) parts.push(`landed and re-proven: ${landed.join('; ')}`)
  if (demoted.length) parts.push(`demoted to a finding below: ${demoted.map(d => `${d.title} (${d.reason})`).join('; ')}`)
  if (dismissed.length) parts.push(`dismissed as not real: ${dismissed.map(d => `${d.title} (${d.reason})`).join('; ')}`)
  return parts.join(' | ')
}

// One PR section per review lane that ran, findings numbered A#/D#/R# - the ids the human triages by.
const renderSection = (id, title, fixedLine, findings) => {
  const lines = [`### ${title}`, '']
  if (fixedLine) lines.push(`_Fixed in-run: ${fixedLine}_`, '')
  if (findings.length) findings.forEach((f, i) => { lines.push(`- **${id}${i + 1}.** ${f.issue}`, `  Recommended: ${f.recommendation}`) })
  else lines.push('_No findings surfaced._')
  return lines.join('\n')
}
const deadSection = (title) => `### ${title}\n\n_The stage died with no result - nothing was reviewed on this lane._`

const prPrompt = (implProofPath, reviewsLine, findingsBlock, auditTable, auditNote, draftReason) => `Open a PR for the change on the current working tree.
Follow ${SKILLDIR}/PR-FORMAT.md for the branch/commit/PR-body conventions, AND the "PR & publish" section of the repo
profile at ${PROFILE} for this repo's specifics - the architecture-section format and vocabulary, the Try-it command,
the evidence bundle location, and the publish command with its credential source and fallback. Read both first; the
profile wins where they differ. The my-build-full-specific additions below are the Reviews line, the per-review
findings sections${RETRO_DEPTH === 'light' ? '' : ', and the Token & time audit section'}.
- The plan is at ${PLAN}. The implementer self-proof is at ${implProofPath} (in temp - read it for the body and for
  the published evidence page, do NOT copy it into the repo or commit it).
- Branch \`build/${SLUG}\` per PR-FORMAT.md (append -2, -3, ... if taken).
${G.fmt ? `- Fmt before the commit: ${G.fmt}. If it reflows a file outside the logical diff, leave that file out of the commit.\n` : ''}${EVIDENCE === 'full' ? `- **Evidence bundle.** Assemble the bundle at the profile's bundle location per PR-FORMAT.md: an \`index.html\`
  that OPENS with the proof's At-a-glance section (the problem in plain language, before, after, each beside its
  single most convincing capture - proof-in-one-screenful for an average reader), then tells the validation story
  claim by claim - the scenario run and the concrete observed results vs what the plan predicted, each
  screenshot/clip from the proof rendered IMMEDIATELY beside the one-line claim it proves (copied in from temp,
  renamed descriptively from its caption), primary behavior first, then each edge the proof reached. (No
  media -> the page is the claim list alone.)` : `- **LIGHT evidence** - the plan's **Scope & risk** section picked \`evidence: light\`. Skip the curated bundle and
  publish the proof artifact itself instead, per PR-FORMAT.md's light variant: at the profile's bundle location,
  write an \`index.html\` that renders the proof artifact at ${implProofPath} AS-IS - its text unedited, each
  screenshot/clip it names embedded by relative path beside its mention - and copy that media in. No re-authoring,
  no renaming, no claim-by-claim curation: light trims packaging, never publishing. Copy no media into the repo and
  commit none, exactly as on a full run.`}
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
- Open a ${draftReason ? `DRAFT PR (\`gh pr create --draft\`) - this run left something unresolved: ${draftReason}. Say that verbatim on the Reviews line (see below)` : 'ready-for-review PR'} against the default branch with \`gh\`. If gh is not authenticated, skip the PR and the
  publish, leave the commit on the branch, and report "PR not opened: gh not authed".
- **Publish the evidence** once the PR number exists, exactly per the profile's publish command and fallback -
  every run publishes: the curated bundle on full, the proof page on light. On success, \`gh pr edit\` the review
  URL into the Validation section. If publishing fails, keep the PR, reference the local path instead, and report
  the publish error - never block the PR on it.
${TICKET ? `- **Work-queue ticket.** This run ships ticket ${TICKET.id}. Once the PR is open and the evidence link is in,
  post the PR URL on the ticket (one line: the URL plus "PR opened by my-build-full"): ${TICKET.note}${draftReason ? `. The PR
  is a DRAFT, so do NOT close the ticket - it stays In Progress until that is resolved; the post-PR triage closes
  it` : `. Then close the ticket: ${TICKET.close}`}. If the PR was not opened (gh not authed), leave the ticket
  untouched. Either way, state the ticket's end state in your return value.
` : ''}- **CI tail** (per PR-FORMAT.md): once the PR is open and the evidence link is in, run \`gh pr checks <number>\`. No
  checks reported -> the repo has no PR CI; move on. Otherwise wait for the checks to conclude (cap the wait at ~15
  minutes); on a failure make AT MOST ONE fix attempt (read the failing log, fix, commit, push, re-check once), then
  stop either way. Fold the final CI state into your return value ("CI green" / "CI red: <reason>" / "CI still
  running after 15m") - a persistently red PR is the human's call, never a reason to loop or close the PR.
- PR body, assembled from the plan + the proof, per PR-FORMAT.md's baseline sections (Objective, Architecture changes
  in the profile's format, Try it from the profile, ${EVIDENCE === 'full' ? `Validation as the \`[Validation evidence](<review URL>)\` link ONLY - no
  claim-by-claim prose in the PR; the claims live on the evidence page` : `Validation as the \`[Proof artifact](<review URL>)\` link ONLY - no
  claim-by-claim prose in the PR; the claims live on the published proof page, told once`}) plus these ${RETRO_DEPTH === 'light' ? 'two' : 'three'} my-build-full sections, in this order:
  - **Reviews** - one bare line naming which reviews ran: \`Reviews: ${reviewsLine}\`. Add reasoning ONLY if
    something is off - ${draftReason ? `and it is: append that this PR opened as a DRAFT because ${draftReason}` : 'a review stage died (the line above says so), or a Retro finding below says the plan\'s review decision was the wrong call - in which case add that one clause. Nothing off -> the bare line alone, no commentary'}.
  - **Review findings (triage before merge)** - paste the block below VERBATIM as the section's content. The \`A#\` /
    \`D#\` / \`R#\` ids are how the human refers to a finding in post-PR triage: do not renumber, reorder, reword,
    merge, or drop any of it, and do not add findings of your own. Preface the section with one line: these are
    triaged before merge - addressed on THIS branch/PR, or consciously waved through; never a follow-up PR.
<<<FINDINGS
${findingsBlock}
FINDINGS>>>
${RETRO_DEPTH === 'light' ? `  This run had a LIGHT retro (the plan's Scope & risk pick), so there is NO Token & time audit section - omit it
  entirely, and write no placeholder standing in for it.` : `  - **Token & time audit** - paste this per-stage table verbatim; it is run-over-run trend data, so it ships even
    when nothing is anomalous:
<<<AUDIT
${auditTable || '_the retro could not produce the audit table this run._'}
AUDIT>>>
${auditNote ? `    Then one line, verbatim: ${auditNote}` : '    Add no prose beneath it - nothing anomalous was reported.'}`}
  The \`<<<...>>>\` markers are delivery wrappers - paste what is between them, never the markers themselves.
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
// (31 runs, one real catch, ~29% of a run's output tokens). Reviewers are read-only and artifact-based; EITHER one's
// fix lane spins up the fix stage. A dead review or a failed fix never kills the run - it downgrades the PR to a
// draft, so the work and the evidence still reach the human.
let adv = null, design = null, fix = null, draftReason = ''
let fixItems = []
if (REV.adversarial || REV.design) {
  phase('Review')
  const [a, d] = await parallel([
    () => REV.adversarial ? agent(advPrompt(impl.proofPath), { phase: 'Review', label: 'review:adversarial', schema: ADV_SCHEMA, model: MODEL, ...AG(AGENTS.light) }) : null,
    () => REV.design ? agent(designPrompt(impl.proofPath), { phase: 'Review', label: 'review:design', schema: DESIGN_SCHEMA, model: MODEL, ...AG(AGENTS.light) }) : null,
  ])
  adv = a; design = d
  if (REV.adversarial && !adv) draftReason = 'the adversarial review stage died - defect status unknown'
  fixItems = [
    ...(adv ? adv.fix.map(f => ({ ...f, lane: 'adversarial' })) : []),
    ...(design ? design.fix.map(f => ({ ...f, lane: 'design' })) : []),
  ]
  if (fixItems.length) {
    const artifacts = [
      adv ? `- the adversarial review's findings: ${adv.findingsPath}` : null,
      design ? `- the design review's findings: ${design.findingsPath}` : null,
    ].filter(Boolean).join('\n')
    fix = await agent(fixPrompt(fixItems, artifacts, impl.proofPath), { phase: 'Review', label: 'fix', schema: FIX_SCHEMA, model: MODEL, ...AG(AGENTS.impl) })
    if (!fix) draftReason = 'the fix stage died with review fix items outstanding'
    else if (fix.outcome !== 'proven') draftReason = fix.blocker || fix.summary
    else {
      // Draft semantics stay narrow: only an unlanded DEFECT or VIOLATION drafts the PR. A demoted improvement is
      // just a finding. (A dismissed item is one the fix stage verified was never real - it drafts nothing.)
      const stuck = fix.demoted.filter(d => { const it = itemByTitle(fixItems, d.title); return it && (it.kind === 'defect' || it.kind === 'violation') })
      if (stuck.length) draftReason = `${stuck.length} confirmed defect/violation(s) left unfixed, demoted to PR finding(s): ${stuck.map(d => `${d.title} (${d.reason})`).join('; ')}`
    }
  }
}

// The Retro always runs - light is its floor, never off. At both depths it checks Done-when conformance and
// proof-vs-diff consistency; a FULL retro adds the token & time audit and the review/scope-decision audit.
phase('Retro')
const laneCounts = (r) => `${r.fix.length} fix item(s), ${r.notes.length} escalated note(s)`
const trajLines = [
  `- Implement: ${impl.outcome}.${TOTAL ? ` (decomposed: ${PAR.length} parallel + ${SEQ.length} sequential pieces, then integrate-and-prove)` : ''} ${impl.summary}`,
]
if (REV.adversarial) trajLines.push(adv ? `- Adversarial review: ${laneCounts(adv)}. ${adv.summary}` : '- Adversarial review: stage died (no result).')
if (REV.design) trajLines.push(design ? `- Design review: ${laneCounts(design)}. ${design.summary}` : '- Design review: stage died (no result).')
if (fixItems.length) trajLines.push(fix ? `- Fix: ${fix.outcome}. Landed ${fix.landed.length}/${fixItems.length}, dismissed ${fix.dismissed.length}, demoted ${fix.demoted.length}. ${fix.summary}` : '- Fix: stage died (no result).')
// The ceremony line is how the guard override reaches a human eye: the retro sees it, and a full retro audits the picks.
trajLines.push(`- Ceremony (the plan's Scope & risk picks): evidence ${EVIDENCE}, retro ${RETRO_DEPTH}.${EVID_FORCED ? ' NOTE: the plan picked evidence light, but a design review was selected and that reviewer judges the evidence bundle, so evidence was FORCED UP to full - the light pick was wrong.' : ''}`)
const trajectory = trajLines.join('\n')
const reviewArtifacts = [
  adv ? `- the adversarial review findings: ${adv.findingsPath} (in temp)` : null,
  design ? `- the design review findings: ${design.findingsPath} (in temp)` : null,
].filter(Boolean).join('\n')
const retro = await agent(retroPrompt(trajectory, impl.proofPath, reviewArtifacts), { phase: 'Retro', label: 'retro', schema: RETRO_SCHEMA, model: MODEL, ...AG(AGENTS.light) })
const R = retro || { findings: [], auditTable: '', auditNote: '', topFinding: '', reviewPath: '' }

// Assemble the PR's per-review sections here so the PR stage pastes them verbatim: the A/D/R ids are how the human
// refers to a finding in post-PR triage, so no stage downstream may reorder, reword, merge, or drop one.
const laneFindings = (lane, notes) => [
  ...notes,
  ...(fix ? fix.demoted : []).filter(d => { const it = itemByTitle(fixItems, d.title); return it && it.lane === lane })
    .map(d => { const it = itemByTitle(fixItems, d.title); return { issue: `${d.title} - flagged for the in-run fix lane, demoted by the fix stage: ${d.reason}`, recommendation: it.change } }),
]
const advFindings = adv ? laneFindings('adversarial', adv.notes) : []
const designFindings = design ? laneFindings('design', design.notes) : []
const retroFindings = R.findings || []
const sections = []
if (REV.adversarial) sections.push(adv ? renderSection('A', 'Adversarial review', fixLine('adversarial', fix, fixItems), advFindings) : deadSection('Adversarial review'))
if (REV.design) sections.push(design ? renderSection('D', 'Design review', fixLine('design', fix, fixItems), designFindings) : deadSection('Design review'))
sections.push(retro ? renderSection('R', 'Retro', '', retroFindings) : deadSection('Retro'))
const reviewsLine = [
  REV.adversarial ? (adv ? 'adversarial' : 'adversarial (STAGE DIED)') : null,
  REV.design ? (design ? 'design' : 'design (STAGE DIED)') : null,
  retro ? (RETRO_DEPTH === 'light' ? 'retro (light)' : 'retro') : 'retro (STAGE DIED)',
].filter(Boolean).join(', ')

phase('PR')
const pr = await agent(prPrompt(impl.proofPath, reviewsLine, sections.join('\n\n'), R.auditTable || '', R.auditNote || '', draftReason), { phase: 'PR', label: 'open-pr', model: MODEL, ...AG(AGENTS.light) })
return {
  status: 'pass', pr, reviewsLine,
  findings: { adversarial: advFindings, design: designFindings, retro: retroFindings },
  fixedInRun: fix ? fix.landed : [], dismissed: fix ? fix.dismissed : [], demoted: fix ? fix.demoted : [],
  auditTable: R.auditTable || '', auditNote: R.auditNote || '',
  retroSummary: R.summary || '', retroFinding: R.topFinding || '', retroPath: R.reviewPath || '',
  evidence: EVIDENCE, evidenceForced: EVID_FORCED, retroDepth: RETRO_DEPTH,
  draft: !!draftReason, draftReason,
}
```

## Step 2b - Decomposed build (pieces)

Reach here from Step 1's **Decomposition decision**: the work has genuine seams
(per the seam test), or it won't fit one implement-context but folds into
independently-green pieces. Decomposition is a deliberate planning-time call
written into the plan doc - it needs no separate user authorization; the seam test
and the **hard cap of 10 pieces** (the script throws above it) are the guardrails.
It is the *same* Step 2 Workflow, driven by data. Decomposing the *build* is still
**one** PR - never slicing the deliverable.

**Size each piece to one impl agent's context - not to the cap.** That is why the
cap sits at 10: a large objective is better served by more, smaller pieces, each
comfortably inside one fresh context, than by a handful of overstuffed ones that
run out of room and come back `blocked`. The cap only marks where an objective
stopped fitting one PR at all; the seam test still decides which splits are legal,
so a high cap never licenses splitting work that has no seam.

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
  lead with `draftReason`: an unresolved defect or design-intent violation (or a
  review stage that died) is the first thing the human must look at. Relay the
  work-queue ticket's end state when the run carried one (closed, or left In
  Progress - the PR stage's return names it). If `evidenceForced` is true, say so
  in one line - the plan asked for light evidence but a design review was selected,
  so the run published a full bundle anyway and the Scope & risk pick was wrong.
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

1. **Relay the triage list.** Print the returned `findings`, lane by lane, with
   the ids the PR uses - `findings.adversarial` as `A1..`, `findings.design` as
   `D1..`, `findings.retro` as `R1..` - each item's issue and recommendation
   verbatim, in the returned order (never renumber or reorder; the ids are how the
   human names them). Then `fixedInRun` in one line ("fixed in-run: ..."), plus
   `demoted` and `dismissed` in one line each if non-empty, then `retroSummary`
   and `retroFinding`. On a full retro (`retroDepth: 'full'`), point at the PR's
   Token & time audit section for the run's cost table rather than reprinting it; a
   light retro has no such section and none is owed (`retroPath` has the fuller
   reasoning at either depth if the human asks). Empty findings everywhere -> say
   the run came back clean and the PR is ready for the human's own read.
2. **The human picks** which findings to address (by id), which to consciously
   skip, plus anything from their own read of the PR. Do not pre-filter, rank, or
   advocate - the worth-addressing judgment is precisely the part of this
   workflow that stays human. Wait for their reply; there is nothing to do
   proactively here.
3. **Address on the SAME branch/PR - never a follow-up PR.** On selection, spawn
   ONE fresh subagent (Agent tool; the profile's impl worker type if it names
   one) seeded with: the PR number and branch, the selected findings' ids plus
   their issue and recommendation verbatim, the plan path, and the profile +
   EVIDENCE.md paths. Its instructions: make the selected changes on the PR
   branch, honoring the plan's Constraints & decisions; run the check gate and
   iteration tests, plus the full gate once if the change is more than trivial;
   re-prove live any proof claim it touched and refresh the affected evidence; if
   the proof or its media changed, rebuild the published page and re-publish per
   the profile (fresh immutable URL -> `gh pr edit` it in) - the curated bundle
   on a full-evidence run, the as-is proof page on a light one
   (`evidence: 'light'`); push to the same branch; comment
   on the PR naming which ids it addressed. Relay its report in a sentence or
   two. Repeat as the human asks for more rounds.
4. **The Retro lane (`R#`) is a different kind of fix.** Those findings are edits
   to this skill or the repo profile, not to the branch - handle them in-session
   with the human when they take one up, or leave them as leads.
5. **Merging stays the human's call.** Never merge, close, or mark the draft
   ready yourself - a draft PR converts only after the defect or violation in its
   `draftReason` is resolved on the branch.
6. **Ticket close-out.** A draft PR (or an unauthed-gh run) leaves the run's
   work-queue ticket In Progress. When the human marks the PR ready after fixes
   (or the PR finally opens), close the ticket with the profile's Work queue
   close verb - one command, run it directly. A ready PR's ticket was already
   closed by the PR stage; nothing to do.
