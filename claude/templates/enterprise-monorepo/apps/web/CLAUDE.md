# apps/web — frontend application

<!-- Loads when Claude is started here, or on demand when it reads a file in
     this directory. Owned by the team that owns this package. -->

<FRAMEWORK> single-page app for <AUDIENCE>. Talks to `apps/api` only.

## Commands

Run from `apps/web/`, never from the repo root.

- Dev: `<DEV_CMD>` (port `<PORT>`)
- Test: `<TEST_CMD>` · Component tests: `<COMPONENT_TEST_CMD>`
- Build: `<BUILD_CMD>`

## Layout

- `src/pages/` — routed views. Composition and data orchestration only.
- `src/components/` — presentational, reusable, no data fetching.
- `src/api/` — the only place that talks to the network. Generated types from
  `packages/shared`.
- `src/stores/` — client state. Server state belongs in the data layer's cache,
  not here.

## Local conventions

- API types come from `packages/shared`. A hand-written interface mirroring a
  response is a defect — it will drift.
- Every async surface renders three states explicitly: loading, empty, error.
- No business rule in the UI. If the client decides who may do what, the server
  is missing a check.
- User-facing error text comes from the API's `error.message`, never from a raw
  exception.
- Accessibility is part of done: labelled controls, keyboard reachable, visible
  focus.

Skills for this package are in `apps/web/.claude/skills/`.
