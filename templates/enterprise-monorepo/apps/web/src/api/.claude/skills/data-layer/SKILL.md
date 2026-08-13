---
name: data-layer
description: Add or change a query, mutation, or API client call in apps/web/src/api. Use when wiring the frontend to an endpoint, handling cache invalidation, or changing how remote data is fetched.
allowed-tools: Read Grep Glob Edit Write
---

# Data layer

Loads only while working in `apps/web/src/api/`. **This is the only directory in
the frontend allowed to talk to the network.**

## Why the restriction is absolute

A component that fetches cannot be reused, cannot be tested without a network
mock, and re-fetches on every remount for reasons nobody can see from the JSX.
Every exception to this rule has been regretted. Keep the fetch here; pass data
down as props.

## Rules

- **Types come from `packages/shared`.** Never declare a local interface for a
  response — it compiles today and drifts the moment the API changes. If the
  type is missing there, add it there.
- One module per resource, mirroring the API's resources — not per screen.
  Screens change; resources don't.
- Every query declares its cache key explicitly and deterministically. A key
  built from an object literal with unstable ordering silently caches nothing.
- **Every mutation states what it invalidates.** The bug this prevents is the
  one users report as "I have to refresh to see my change".
- Errors surface as the API's `error` object, unchanged. Do not re-wrap it, do
  not stringify it — components need `error.code` to branch and
  `error.message` to display.
- No retry on a `4xx`. Retrying a `422` just sends the same invalid payload
  again, three times, slowly.

## Loading and empty are data-layer concerns too

Expose `isLoading`, `isEmpty` and `error` as first-class parts of the return
value. If a component has to derive "empty" from `data?.length === 0`, every
component will derive it differently and one of them will be wrong for `null`.

## Before adding an endpoint call

Check the generated client and this directory first — the call often already
exists under a name you didn't guess. Two hooks fetching the same resource with
different keys means two cache entries, double the requests, and a UI that
disagrees with itself.
