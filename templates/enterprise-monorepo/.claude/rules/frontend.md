---
description: Frontend conventions — loaded when touching apps/web
paths:
  - "apps/web/**"
---

# Frontend (`apps/web`)

- **Never redeclare API types.** Import them from `packages/shared`; a local
  interface mirroring a response is a defect.
- Components are presentational by default. Data fetching, caching and mutation
  live in the data layer (`<DATA_LAYER_PATH>`), not inside components.
- Every async surface handles three states explicitly: loading, empty, error.
  A component that only renders the happy path is incomplete.
- Errors shown to users come from the API `error.message`, never from a raw
  exception or a stack trace.
- No business rule in the UI. If the client decides who may do what, the server
  is missing a check.
- Accessibility is part of done: labelled controls, keyboard reachable, focus
  visible, meaningful alt text.
- Keep bundle discipline: no new dependency for something the platform already
  does; lazy-load anything route-specific.

Run from `apps/web/`, not the repo root.
