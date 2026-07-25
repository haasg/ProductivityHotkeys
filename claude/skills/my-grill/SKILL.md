---
name: my-grill
description: A full grilling session that challenges your plan against the domain model, sharpens terminology, and updates documentation (glossary, ADRs, architecture invariants) inline as decisions crystallise - batching independent questions into multi-question rounds to cut the back-and-forth. Use when you want to stress-test a plan against your project's language and documented decisions.
---

<what-to-do>

**Step 0 - check the invocation itself.** If the arguments still contain unfilled
template placeholders (a literal `<TOPIC - fill in>`, `<WHAT IT BUILDS…>`, or any
`<… fill in …>` marker), STOP before loading any context and ask for the missing
topic/scope in one short message. A grill fired from an unfilled handoff template
burns heavy context-loading it cannot use - there is no topic to sanity-check
against.

**Step 0.5 - load the repo profile.** This skill is shared across repos; the
repo-specific parts come from a profile.

1. Resolve the key: the basename of `git remote get-url origin`, minus `.git`
   (so `https://github.com/haasg/PixelGenerator.git` gives `PixelGenerator`). It
   is stable across worktrees. No git repo or no `origin`? Use the repo root
   directory name.
2. Read `$env:USERPROFILE\.claude\skill-profiles\<key>.md` **in full** before
   asking the first question.
3. If there is no file for the key, read `_default.md` from the same directory and
   say once, in one short line: "No profile for `<key>`; running generic - add one
   at `ProductivityHotkeys/claude/profiles/<key>.md`." Then continue.

Everywhere below that names *the profile*, use what that file says. Never carry
another repo's vocabulary, toolchain, or conventions into this session.

Interview me until we reach shared understanding - walk every branch of the design
tree, challenge the plan against the existing domain model, sharpen terminology,
and update the docs inline as decisions crystallise. **Batch every independent
question into a single round** so I can answer many at once and we get through the
tree in fewer turns. Loop round after round until there are no open branches left.

If a question can be answered by exploring the codebase, explore the codebase
instead. Never ask me what the code already tells you. The same discipline applies
to decisions you resolve yourself: when a recommendation or an announced technical
decision relies on an existing field or mechanism's scope, persistence, or
behavior, **verify that property in the code** (or the governing ADR/design doc)
before pinning it. A decision nobody reviews gets no check except this one.

### Batching: what goes together, what waits

Before each round, map the dependencies between the open questions:

- **Independent questions go in the same round.** If question B's framing does not
  change based on the answer to question A, ask them together.
- **Dependent questions wait.** If the *next* question only exists, or would be
  worded differently, depending on how I answer a current one, hold it for the
  next round. Don't guess my answer to pre-pose a downstream question.
- When unsure whether two questions are independent, default to batching them - a
  slightly-coupled pair in one round costs less than an extra turn. Only split
  when one genuinely gates the other.

So a session is a sequence of rounds: each round is as wide as the independent
questions allow, and the number of rounds is as deep as the real dependency chains
demand. Tell me briefly when a round is deliberately small because the remaining
questions are gated on these answers ("answering these unlocks the next set").

### How to present a round

Do **not** use the `AskUserQuestion` tool (the built-in option selector UI) - it
caps at four options-style questions and can't carry a wide batch. Always ask as
**plain text in the conversation**.

Present all questions in the round at once, numbered. For each question, give your
**recommended answer and the reasoning** behind it. When a question has discrete
options, label them with lowercase letters on their own lines and mark your
recommendation:

```
1. What should `cancellation` mean in the Orders context?

   a) Voiding the entire order before fulfillment (my recommendation - matches existing usage in src/ordering/)
   b) Refunding individual line items after fulfillment
   c) Both, distinguished by an `OrderState` enum

2. Where should the retry budget live - per-request or per-session?

   a) Per-session (my recommendation - the rate limiter is already session-scoped)
   b) Per-request

   ...
```

For open-ended questions (no discrete options), just ask in prose - don't invent
fake options to fit the a/b/c format. Make every question answerable in one pass
so I can reply to the whole round in a single message.

</what-to-do>

<supporting-info>

## Domain awareness

During codebase exploration, read the documentation the profile's **Docs** section
names: the glossary, the decision records, and the invariants file. The profile
tells you their real paths and whether this repo has one context or several - do
not assume `CONTEXT.md` at the root.

Create files lazily - only when you have something to write. If the glossary
doesn't exist, create it when the first term is resolved. If the ADR directory
doesn't exist, create it when the first ADR is needed. Both go where the profile
says they go.

## During the session

### Challenge against the glossary

When I use a term that conflicts with the existing language in the glossary, call
it out immediately. "Your glossary defines 'cancellation' as X, but you seem to
mean Y - which is it?"

### Sharpen fuzzy language

When I use vague or overloaded terms, propose a precise canonical term. "You're
saying 'account' - do you mean the Customer or the User? Those are different
things."

**Collision-check a new term at its FIRST naming moment** - grep the glossary and
term index the moment a candidate name surfaces, not at a later terms-wrap pass.
A deferred check forces back-edits across every doc that already used the name,
and usually leaves residual informal usage behind.

### Discuss concrete scenarios

When domain relationships are being discussed, stress-test them with specific
scenarios. Invent scenarios that probe edge cases and force precision about the
boundaries between concepts. A scenario that exposes a hidden decision is itself a
question worth adding to the next round.

### Cross-reference with code

When I state how something works, check whether the code agrees. If you find a
contradiction, surface it: "Your code cancels entire Orders, but you just said
partial cancellation is possible - which is right?"

**Existence-probe the carrying surface.** When a plan line says "add a
marker/row/field/command to X," verify during the session that X exists in code.
A marker with no surface to ride on, or a validation route with no way to trigger
it, silently grows the work's real surface beyond the grill's estimate.

**Re-walk identity derivation when a concept gains multiplicity.** When the plan
turns a one-of-each concept into a roster of several instances sharing one kind,
re-walk every existing per-instance identity-derivation call site against the new
multiplicity. A "derive the kind from the id" premise is silently false once
instances share a kind, and it survives grills that don't look for it.

### Challenge the boundaries

When the plan touches the profile's unit boundaries or their interfaces, run a
boundary pass: generate a few alternatives, stress-test the chosen one, and let me
select. Architecting boundaries is a design step we do *here*, not something left
to the implementation agent. The procedure - the lead question, the critic moves,
and where a resolved decision gets recorded - lives in
[./BOUNDARY-DESIGN.md](./BOUNDARY-DESIGN.md). How much ceremony to apply is the
profile's **Boundary ceremony** section, and it varies a lot by repo and by area
within a repo; read it before deciding how picky to be.

### Update the glossary inline

When a term is resolved, update the glossary right there. Don't batch these doc
updates to the end - capture them as they happen, across rounds. (Batching applies
to *questions*, not to *doc writes*.) Use the format in
[./CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md), plus any term-index rule the profile's
**Docs** section names.

**One exception, and only if the profile's Batch workflow section says the repo
has one:** when a worker is in flight on this branch, tracked-doc writes would
race its commit. Stage instead of landing, exactly as the profile describes, and
land the drafts verbatim at the join after the worker commits. Decisions are still
captured immediately; only the tracked-file write waits.

The glossary should be totally devoid of implementation details. Do not treat it
as a spec, a scratch pad, or a repository for implementation decisions. It is a
glossary and nothing else.

### Update the architecture invariants inline

When a decision adds or changes a cross-cutting invariant, update the profile's
**Invariants** file in the same pass, exactly as you would an ADR. It holds the
invariants every change must preserve, and nothing else. The profile names this
repo's invariants explicitly - use those names.

When a decision instead moves a box or changes a channel, that is a **boundary
graph** change, and the profile's **Module vocabulary** section says where it
lands. In most repos that is not the invariants file. Keep both honest as
decisions crystallise.

### Offer ADRs sparingly

Default to **no**. Only offer to create an ADR when all three are true:

1. **Hard to reverse** - the profile's **ADR bar** section defines what "hard to
   reverse" means concretely in this repo. If a single PR can flip it, it is not
   an ADR, no matter how good the "why" is.
2. **Surprising without context** - a future reader will wonder "why did they do
   it this way?"
3. **The result of a real trade-off** - there were genuine alternatives and you
   picked one for specific reasons.

Gates #2 and #3 are cheap to clear; **gate #1 is the real bar.** The profile also
lists what specifically does *not* warrant an ADR in this repo - read it, because
the answer differs sharply between repos. If gate #1 isn't clearly met, skip the
ADR. See [./ADR-FORMAT.md](./ADR-FORMAT.md) for the format.

### Pin the contracts the next piece of work will consume

When the work being grilled creates something a *later* piece will read - a state
field, a function signature, a record shape, an event payload - crystallise that
narrow contract explicitly before wrap-up: exact names, types, semantics. Pin only
what the next piece consumes; leave the rest of the surface to the implementer.
Pins are binding on the implementer: a deviation is surfaced and renegotiated,
never silent.

Where a pin is recorded, and whether it also becomes a durable batch artifact, is
the profile's **Batch workflow** section.

**Enumerate the dynamic inputs a pinned signature must carry.** When pinning a
hook or chokepoint signature, list every input its pinned *semantics* require that
changes over time - a position, a meter, a clock - and confirm the signature can
actually carry each one. A context object built once per run cannot supply
per-turn state, and that mismatch is invisible until implementation.

**Check pinned arithmetic against current source values in-grill.** A grill that
pins a numeric claim, a validation leg, or a universal statement reads the relevant
constant and content files DURING the session. Pinning a leg that current values
make unreachable, or a principle already false for shipped content, wastes the
build that inherits it.

**Tag validation legs that the implementing work cannot reach.** A leg only a full
run or a long staged drive can reach must not be assigned to the implementing build
as a required leg. How to tag it is the profile's **Batch workflow** section;
outside a batch, name it explicitly in the plan as a follow-up proof with its
staging moment. Never leave it silently required of a build that cannot reach it.

### Apply the profile's domain lessons

The profile's **Domain lessons** section holds rules that are true in this repo and
the incidents that taught them. Read them at the start and apply them throughout;
they are the cheapest source of edge cases this repo has already paid for.

### Wrap up: hand off to a build

**Write the decisions ledger once, point everywhere else.** Distill the session's
rulings into ONE canonical home, and make everything downstream POINT at it instead
of restating. The profile's **Batch workflow** section names that home for this
repo. Without one, the design doc's Decided block, or the single plan doc handed to
the build, is the home - same principle, no extra artifacts. Re-transcribing each
ruling into several docs is how drift starts.

When the grilling reaches shared understanding (no open branches left), restate the
resolved decisions briefly so the alignment is explicit in the conversation, then
stop and list the execution options the profile's **Wrap-up options** names.

Do **not** launch any of them yourself - pulling the trigger is the user's call.

</supporting-info>
