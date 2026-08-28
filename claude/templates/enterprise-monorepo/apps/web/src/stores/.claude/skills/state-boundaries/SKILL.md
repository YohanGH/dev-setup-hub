---
name: state-boundaries
description: Add or change client state in apps/web/src/stores — and decide whether something belongs in a store at all. Use when adding global state, a store slice, or debugging state that disagrees with the server.
allowed-tools: Read Grep Glob Edit Write
---

# State boundaries

Loads only while working in `apps/web/src/stores/`.

## The question that prevents most frontend bugs

**Who owns the truth for this value?**

| Owner | Where it lives | Never |
|-------|----------------|-------|
| The server | the data layer's cache (`src/api`) | copied into a store |
| The URL | route params and query string | mirrored in a store |
| One component | local component state | lifted "just in case" |
| The whole app, client-only | **here** | anything the server also knows |

**Server data does not belong in a store.** The moment you copy a fetched
invoice into a store, you own cache invalidation by hand, and the UI starts
disagreeing with the database in ways that only reproduce for one user on
Tuesdays. The data layer already caches; use it.

## What legitimately lives here

Genuinely client-only, genuinely global state: theme, locale, sidebar
collapsed, a multi-step form in progress, an optimistic queue, feature-flag
overrides for local dev. That list is short on purpose — if your stores
directory has fifteen files, most of them are one of the other three owners.

## Rules

- **No fetching in a store.** Stores are synchronous state; the data layer is
  asynchronous truth. Mixing them puts request lifecycle into global state,
  where nothing can clean it up.
- Derive, don't duplicate. A value computable from two others is a selector, not
  a field — a stored derivative is a stored opportunity for the two to disagree.
- Actions are named for the **user intent** (`dismissedOnboarding`), not the
  mutation (`setFlag`). You will read these in a debugger at some point.
- Anything persisted to storage needs a version and a migration path. Shipping a
  shape change without one breaks every returning user, silently, on load.
- Never store a token or anything secret. It is readable by any script on the
  page.

## Debugging "the UI is stale"

Ninety percent of the time the value has two owners: it is in a store *and* in
the data-layer cache. Find the duplicate and delete the store copy — do not add
a synchronisation effect. The effect is a third owner.
