# ADR Format

The profile's **Docs** section names where ADRs live and how they are numbered
(some repos split them into per-area folders with independent numbering). Create
the directory lazily - only when the first ADR is needed.

## Template

```md
# {Short title of the decision}

{1-3 sentences: what's the context, what did we decide, and why.}
```

That's it. An ADR can be a single paragraph. The value is in recording *that* a
decision was made and *why* - not in filling out sections.

## Optional sections

Only include these when they add genuine value. Most ADRs won't need them.

- **Status** frontmatter (`proposed | accepted | deprecated | superseded by
  ADR-NNNN`) - useful when decisions are revisited
- **Considered Options** - only when the rejected alternatives are worth
  remembering
- **Consequences** - only when non-obvious downstream effects need to be called
  out

## Numbering

Scan the ADR directory for the highest existing number and increment by one. Where
the profile says ADRs are split per area, number within that area and cite them
with the area name (for example "engine ADR 0031").

## When to offer an ADR

Default to **no**. An ADR is the exception, not the record of every decision. All
three of these must be true:

1. **Hard to reverse.** The profile's **ADR bar** section defines what this means
   concretely here - which surfaces are expensive to unwind in this repo. **If a
   single PR can flip it, it is not an ADR**, no matter how good the "why" is.
2. **Surprising without context** - a future reader will look at the code and
   wonder "why on earth did they do it this way?"
3. **The result of a real trade-off** - there were genuine alternatives and you
   picked one for specific reasons.

Gates #2 and #3 are cheap to clear; there is almost always a "why" and an
"alternative." **Gate #1 is the real bar.** If it isn't clearly met, skip the ADR.

### What does NOT warrant an ADR

The profile lists this repo's specific carve-outs, and they differ sharply between
repos - read that list. The general shape: anything that records a *why* but is
reversible in a single PR belongs in a code comment, the commit message, or the
glossary, not an ADR. Tuning values, presentation choices, single-screen
interaction defaults, and content models confined to one unit are the usual
offenders.

### What qualifies

- **Architectural shape.** "We're using a monorepo." "The write model is
  event-sourced, the read model is projected into Postgres."
- **Integration patterns between contexts.** "Ordering and Billing communicate via
  domain events, not synchronous HTTP."
- **Technology choices that carry lock-in.** Database, message bus, auth provider,
  deployment target. Not every library - just the ones that would take a quarter
  to swap out.
- **Boundary and scope decisions.** "Customer data is owned by the Customer
  context; other contexts reference it by ID only." The explicit no-s are as
  valuable as the yes-s.
- **Deliberate deviations from the obvious path.** "We're using manual SQL instead
  of an ORM because X." Anything where a reasonable reader would assume the
  opposite. These stop the next engineer from "fixing" something that was
  deliberate.
- **Constraints not visible in the code.** "We can't use AWS because of compliance
  requirements." "Response times must be under 200ms because of the partner API
  contract."
- **Rejected alternatives when the rejection is non-obvious.** If you considered
  GraphQL and picked REST for subtle reasons, record it - otherwise someone will
  suggest GraphQL again in six months.
