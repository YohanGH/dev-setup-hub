---
description: Backend service conventions — loaded when touching apps/api
paths:
  - "apps/api/**"
---

# Backend (`apps/api`)

Non-negotiables — the detail is in `.claude/conventions/api-design.md`, read it
before designing or changing an endpoint.

- **Validate at the boundary.** Every inbound payload goes through the shared
  schema layer; unknown fields are rejected, not ignored.
- **One error shape** for the whole API: `{ error: { code, message, details, traceId } }`.
  `code` is a stable enum clients branch on — never reword it.
- **Authorization is checked in the handler that owns the resource**, never
  assumed from the router. Deny by default.
- **Additive changes only** inside `/api/v1/`. Removing or renaming a field,
  tightening validation, or changing a status code is a new version.
- Controllers stay thin: transport in, domain call, transport out. Business
  rules live in the service/domain layer where they are testable without HTTP.
- Request/response types are generated into `packages/shared` and imported by the
  web client — never hand-written twice.
- No raw SQL string interpolation anywhere, including migrations and scripts.

Run from `apps/api/`, not the repo root.
