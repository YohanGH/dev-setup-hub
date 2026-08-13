---
name: component-patterns
description: Build or change a component in apps/web — props, state, data fetching, loading and error states, accessibility. Use when adding a component, a page, or touching the data layer of the frontend.
when_to_use: Triggered while working on files under apps/web/src/.
allowed-tools: Read Grep Glob Edit Write Bash
---

# Component patterns

Only loads for frontend work. Read a neighbouring component of the same kind
before writing a new one — matching local precedent matters more than this file.

## Where things go

| Kind | Location | May fetch? | May hold state? |
|------|----------|-----------|-----------------|
| Page / route view | `src/pages/` | orchestrates, via the data layer | route/UI state only |
| Feature component | `src/components/<feature>/` | no | local UI state |
| Primitive | `src/components/ui/` | no | none — fully controlled |
| Data hook / composable | `src/api/` | yes, the only place | cache only |

A component that fetches is a component that cannot be reused or tested cheaply.
Push the fetch up into the page or into the data layer.

## Props

- Props are the component's API: name them for meaning (`invoice`), not for
  wiring (`data`).
- Required by default; optional only with a sensible default.
- Never pass a whole domain object when the component uses two fields — the
  narrow prop set documents the real dependency.
- Callbacks are `onSomethingHappened`, and describe the event, not the handler's
  implementation (`onInvoiceSelected`, not `onClickRow`).

## The three states — non-negotiable

Every surface that reads remote data renders:

1. **Loading** — a skeleton matching the final layout, not a spinner that shifts
   everything when it resolves.
2. **Empty** — distinct from loading, and it says what the user can do next.
3. **Error** — the message from `error.message`, plus a retry affordance. Never
   a raw exception, never a silent blank.

A component that only handles the happy path is incomplete, and review treats it
as such.

## Types

Import request/response types from `packages/shared`. If a type you need is
missing there, add it there — do not declare a local mirror. Local mirrors drift
the moment the API changes, and nothing fails until production.

## Accessibility

- Every interactive element is a real control (`button`, `a`, `input`) or has
  the right role plus keyboard handling.
- Every input has a programmatically associated label.
- Focus is visible and never trapped; a modal returns focus on close.
- Colour is never the only carrier of meaning.

## Performance

- Lazy-load route-level chunks.
- Memoize only after measuring — premature memoization adds bugs and hides them.
- Never fetch inside a list item. Lift the query, pass the data down.

## Testing

Test what the user experiences: rendered text, roles, and interactions. Do not
assert on internal state or on class names. Snapshot tests of large trees are
not accepted (`.claude/conventions/testing.md`).
