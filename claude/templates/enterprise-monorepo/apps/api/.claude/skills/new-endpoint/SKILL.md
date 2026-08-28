---
name: new-endpoint
description: Scaffold a new REST endpoint in apps/api with validation, authorization, error mapping, OpenAPI annotation and tests. Use when adding a route, a resource, or an action to the API.
argument-hint: <resource> [action]
arguments: resource action
allowed-tools: Read Grep Glob Edit Write Bash
---

# New endpoint — `$resource`

Follow the existing shape of this package rather than a generic template:
**read one neighbouring resource end to end first** (`src/routes/`,
`src/services/`, `src/schemas/`, its tests) and match it. Local precedent beats
this checklist wherever they disagree.

## Create

1. **Schema** — `src/schemas/$resource.ts`
   Request and response schemas. Unknown fields rejected. Types export into
   `packages/shared` so `apps/web` imports them instead of redeclaring.

2. **Route** — `src/routes/$resource.ts`
   Transport only: parse, validate, call the service, map the result. No
   business logic, no database access. Declare the authorization rule
   **explicitly** on the handler — never rely on the router being mounted behind
   something.

3. **Service** — `src/services/$resource.ts`
   The actual rules. Throws domain errors; it does not know about HTTP.

4. **Data access** — `src/db/$resource.ts`
   Parameterized queries only.

5. **Tests** — `src/__tests__/routes/$resource.test.ts`
   Per the `api-testing` skill: happy path, validation → `422` with the field,
   authorization → `403`/`404`, absence → `404`, and the domain rule itself.

6. **Register** the route and update the OpenAPI annotations.

## Contract checklist

- [ ] Status codes match `.claude/conventions/api-design.md`: `201` + `Location`
      on create, `204` on delete, `422` on semantic invalidity.
- [ ] Errors use the shared shape; every new `code` is a **new stable enum
      value**, documented, never reworded later.
- [ ] Additive only if this touches an existing endpoint. Removing or renaming a
      field, or tightening validation, needs a new API version.
- [ ] Writes are idempotent or accept `Idempotency-Key`.
- [ ] List endpoints are cursor-paginated with a server-side `limit` cap, and
      sort/filter fields are allowlisted.
- [ ] No unbounded query. If the table grows, the endpoint must still be safe.

## Then

Run from `apps/api/`:

```bash
<TEST_CMD> src/__tests__/routes/$resource.test.ts
```

Report what passed. Do not commit unless asked.
