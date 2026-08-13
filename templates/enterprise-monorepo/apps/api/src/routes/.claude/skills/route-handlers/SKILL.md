---
name: route-handlers
description: Write or change an HTTP route handler in apps/api/src/routes — parsing, validation, status codes, error mapping. Use when adding or editing a route, controller, or endpoint handler.
allowed-tools: Read Grep Glob Edit Write
---

# Route handlers

Loads only while working in `apps/api/src/routes/`. The frontend, the services
layer and the shared package never pay for these lines.

## The one rule

**A handler is transport, not logic.** Parse → validate → call a service → map
the result. If a handler contains an `if` that encodes a business decision, that
decision is in the wrong file.

```ts
// the shape every handler follows
const body = InvoiceCreateSchema.parse(req.body);   // validate at the boundary
const invoice = await invoiceService.create(userId, body);  // decide elsewhere
return res.status(201).location(`/invoices/${invoice.id}`).json(invoice);
```

## Checklist

- [ ] Input validated with the schema from `../schemas`. Unknown fields rejected,
      not ignored.
- [ ] **Authorization declared on this handler**, resolved from the session —
      never from a client-supplied id, never assumed from where the router is
      mounted.
- [ ] Status codes per `.claude/conventions/api-design.md`: `201` + `Location`
      on create, `204` on delete, `422` on semantic invalidity, `404` when
      absence *or* privilege hides the resource.
- [ ] Domain errors mapped centrally, not with a `try/catch` per handler.
- [ ] No `await` in a loop over request data — that is an N+1 waiting to happen.
- [ ] OpenAPI annotation updated in the same edit.

## Forbidden here

These are enforced by a hook, not just asked for:

| Not allowed | Because | Instead |
|-------------|---------|---------|
| Importing `../db` or a query builder | the handler becomes untestable without HTTP, and SQL leaks into transport | call a service |
| Raw SQL strings | injection surface, and it hides the data model | `../db` via a service |
| `process.env` reads | config resolved at boot, not per request | inject config |
| Business branching on user state | logic that belongs where it can be unit-tested | a service method |

## Tests

Every handler gets, at minimum: happy path, `422` on bad input asserting the
offending field, `403`/`404` on the authorization path. See the `api-testing`
skill.
