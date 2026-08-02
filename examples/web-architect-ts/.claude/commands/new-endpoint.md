---
description: Scaffold a NestJS REST resource (controller, service, DTOs, e2e test)
argument-hint: <resource-name> (singular, e.g. "invoice")
---

Scaffold a new REST resource named **$1** in `apps/api`, following
`.claude/rules/nestjs-api.md`.

Create, under `apps/api/src/$1/`:

1. `$1.module.ts` — wires the controller and service.
2. `$1.controller.ts` — thin controller with the standard routes:
   `GET /$1s`, `GET /$1s/:id`, `POST /$1s`, `PATCH /$1s/:id`, `DELETE /$1s/:id`,
   correct status codes (`201` create, `204` delete, `404` missing).
3. `$1.service.ts` — business logic; controller stays thin.
4. `dto/create-$1.dto.ts` and `dto/update-$1.dto.ts` — `class-validator`
   decorators; `update` extends `PartialType(create)`.
5. Shared request/response **types in `packages/`** so the Vue client reuses them.
6. `@nestjs/swagger` annotations on the controller.
7. `apps/api/test/$1.e2e-spec.ts` — e2e tests per
   `.claude/rules/testing.md`: happy path, validation rejects bad input, `404`.

Then register the module, run `yarn typecheck` and the new e2e test, and report
what passed. Don't commit unless I ask.
