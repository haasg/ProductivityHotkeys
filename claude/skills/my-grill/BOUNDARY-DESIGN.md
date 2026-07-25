# Boundary Design

How to grill boundary and interface decisions. Architecting the dependencies and
interfaces between a repo's units - crates, modules, packages, services, whatever
the profile's **Module vocabulary** calls them - is a **human-in-the-loop design
step during grilling**, not something left implicitly to an implementation-time
agent. The agent generates alternatives and stress-tests them; **the human
selects**.

Where the repo documents its own design philosophy, the profile's **Docs** section
names it. Read that; don't restate it here.

## The lead question

> Can we expose a **small, higher-level, reusable and testable verb over a LARGE
> amount of code**, instead of reaching down into a lower-level unit's internals?

Isolation-by-re-abstraction is the point: a single tested boundary that every
consumer goes through. This is the primary move - ask it first, every time.

## Supporting critic moves

Generate 2-3 boundary alternatives with their trade-offs, then stress-test the
chosen one: *what does a consumer need that this misses? where will someone reach
around it?* Apply these tests as you go:

1. **Deep-vs-shallow test.** Do the facade's public signatures mention the
   underlying unit's types? Then it's *forwarding*, not a boundary. A deep facade
   owns its own boundary types and never leaks them.

2. **Leak-is-structural diagnosis.** Is a genuinely-shared capability squatting
   inside one unit with no home of its own? The reach-in is the architecture
   telling you the capability needs its own home. Fix it by construction (give it
   a home), not by vigilance (asking people not to reach in).

3. **Dependency-direction check.** Can we delete a sibling or cross-layer edge by
   pulling the shared capability *down* a layer, so the internal isn't even
   nameable from the would-be leaker?

4. **Interface-decision rule.** Use an abstraction point - a trait, an interface,
   a protocol - only for *genuine polymorphism*: two or more implementations, or a
   real fake/swap/test need. Otherwise use a concrete type with inherent methods
   and privacy. A one-implementation abstraction is overhead; extract it later
   when the second implementation appears.

## How much ceremony

This is the part that varies most between repos, and the profile's **Boundary
ceremony** section governs it. Read it before deciding how picky to be: most repos
have areas that deserve a full, picky pass (multi-consumer, long-lived,
low-reversibility) and areas that deserve a light touch (one consumer, cheap to
reverse). Applying the heavy pass everywhere is its own failure mode - it
proceduralizes changes that should have been quick.

The universal secondary axis, within any area: stability and blast radius.
Load-bearing or hard-to-reverse boundaries get more ceremony; exploratory or
churning code gets "boundary deferred, let it emerge, tripwires keep it visible."

## Recording a resolved boundary decision

Three sinks. The ADR bar is deliberately **high**.

- **Default sink - a doc-comment at the top of the unit**: the unit's
  one-sentence job, its allowed dependencies, and the higher-level verb it
  exposes. This is what agents read while working, so co-locate the contract with
  the code. Keep it to those three things - a small interface decision is one
  line, not a paragraph; the header is a contract, not a design-history log.

- **ADR - the EXCEPTION, not the rule:** only when the full three-part test in
  [./ADR-FORMAT.md](./ADR-FORMAT.md) holds, against the profile's definition of
  "hard to reverse." Small interface decisions get a doc-comment, NOT an ADR.

- **Never the glossary** - it is a glossary, and no boundary or implementation
  detail belongs there.

## Enforcement is recorded, not built

The grill records the *intended* enforcement as part of the decision so a later
build or tooling task can wire it: which public surface to snapshot, which
dependency edges to forbid, which visibility lint applies. The profile's
**Boundary ceremony** section says what enforcement tooling actually exists in
this repo today. The grill does **not** build the tooling; it captures intent in
the decision.
