# Glossary Format

The profile's **Docs** section names this file's real path and whether the repo
has one context or several. This document is only about what goes *inside* it.

## Structure

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## Language

**Order**:
{A one or two sentence description of the term}
_Avoid_: Purchase, transaction

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request

**Customer**:
A person or organization that places orders.
_Avoid_: Client, buyer, account
```

## Rules

- **Be opinionated.** When multiple words exist for the same concept, pick the
  best one and list the others as aliases to avoid.
- **Flag conflicts explicitly.** If a term is used ambiguously, call it out in
  "Flagged ambiguities" with a clear resolution.
- **Keep definitions tight.** One or two sentences max. Define what it IS, not
  what it does.
- **Show relationships.** Use bold term names and express cardinality where
  obvious.
- **Only include terms specific to this project's context.** General programming
  concepts (timeouts, error types, utility patterns) don't belong even if the
  project uses them extensively. Before adding a term, ask: is this a concept
  unique to this context, or a general programming concept? Only the former
  belongs.
- **Group terms under subheadings** when natural clusters emerge. If all terms
  belong to a single cohesive area, a flat list is fine.
- **Maintain the term index where one exists.** Some repos keep a term index near
  the top and pin it with a test - the profile's **Docs** section says whether
  this one does. Where it does, every entry added or renamed updates its index
  line too, and the pinning test runs before committing. A missed index line turns
  the workspace gate red for the next worker.
- **Write an example dialogue.** A conversation between a dev and a domain expert
  that demonstrates how the terms interact naturally and clarifies boundaries
  between related concepts.

## Single vs multi-context repos

**Single context (most repos):** one glossary file at the repo root.

**Multiple contexts:** a `CONTEXT-MAP.md` lists the contexts, where they live, and
how they relate:

```md
# Context Map

## Contexts

- [Ordering](./src/ordering/CONTEXT.md) - receives and tracks customer orders
- [Billing](./src/billing/CONTEXT.md) - generates invoices and processes payments
- [Fulfillment](./src/fulfillment/CONTEXT.md) - manages warehouse picking and shipping

## Relationships

- **Ordering -> Fulfillment**: Ordering emits `OrderPlaced` events; Fulfillment consumes them to start picking
- **Fulfillment -> Billing**: Fulfillment emits `ShipmentDispatched` events; Billing consumes them to generate invoices
- **Ordering <-> Billing**: Shared types for `CustomerId` and `Money`
```

The profile states which structure this repo uses. If it doesn't, infer: a context
map at the root means multiple contexts; a lone glossary means one; neither means
create one lazily when the first term is resolved.

When multiple contexts exist, infer which one the current topic relates to. If
unclear, ask.
