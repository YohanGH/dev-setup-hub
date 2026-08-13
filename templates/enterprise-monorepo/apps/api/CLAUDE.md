# apps/api — backend service

<!-- Loads when Claude is started here, or on demand when it reads a file in
     this directory. Owned by the team that owns this package. -->

REST API for <DOMAIN>. <FRAMEWORK> on <RUNTIME>, <DATABASE> via <ORM>.

## Commands

Run these from `apps/api/`, never from the repo root.

- Dev server: `<DEV_CMD>` (port `<PORT>`)
- Test: `<TEST_CMD>` · single file: `<TEST_CMD> <path>`
- Migrations: `<MIGRATE_CMD>` — see `.claude/rules/migrations.md` first
- Env: copy `.env.example` to `.env`; the app refuses to boot on a missing var

## Layout

- `src/routes/` — transport only. One file per resource, thin handlers.
- `src/services/` — business rules. This is where the logic lives and where it
  is tested without HTTP.
- `src/db/` — data access. **No SQL strings in route handlers, ever.**
- `src/schemas/` — request/response validation; types generate into
  `packages/shared`.
- `src/__tests__/` — mirrors `src/`.

## Local conventions

- A new endpoint is not done until it has: validation, an explicit authorization
  rule, the shared error shape, an OpenAPI annotation, and a test for the
  rejection path.
- Errors thrown from services are domain errors; the HTTP layer maps them to
  status codes in one place.
- Never widen a response type without checking `apps/web` for consumers.

Detail: `.claude/conventions/api-design.md`. Skills for this package are in
`apps/api/.claude/skills/`.
