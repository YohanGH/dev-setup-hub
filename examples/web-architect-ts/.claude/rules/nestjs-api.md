---
paths:
  - "apps/api/**/*.ts"
---

# NestJS REST API

Loads only for backend files.

## Structure

- One **module per resource**: `controller` (HTTP) → `service` (logic) →
  repository/provider (data). Keep business logic out of controllers.
- Controllers are thin: validate input, call the service, shape the response.

## REST conventions

- Resource-based routes, plural nouns: `GET /users`, `POST /users`,
  `GET /users/:id`, `PATCH /users/:id`, `DELETE /users/:id`.
- Correct status codes: `201` on create, `204` on delete, `404` when absent.
- **DTOs with `class-validator`** on every body/query; enable a global
  `ValidationPipe({ whitelist: true })`.
- Errors go through Nest's `HttpException` hierarchy and serialize to the shared
  error shape used by the frontend — don't invent per-endpoint error formats.
- Expose types in `packages/` so the Vue client imports the same request/response
  types (single source of truth).

## Docs & safety

- Annotate endpoints for **OpenAPI** (`@nestjs/swagger`) so the contract stays
  discoverable.
- Never log secrets or full request bodies that may contain them.
