# API design

> Adapt to your transport. This file assumes a REST/HTTP JSON API; the same
> discipline applies to GraphQL or RPC — the contract is the product.

## Resources and URLs

- Plural nouns, kebab-case: `/api/v1/credit-notes`.
- Nesting one level max: `/invoices/{id}/lines`. Deeper means you need a filter
  (`/lines?invoiceId=`), not a deeper path.
- Verbs never appear in paths. An action that isn't CRUD is a sub-resource:
  `POST /invoices/{id}/finalization`, not `POST /finalizeInvoice`.

## Methods and status codes

| Action | Method | Success |
|--------|--------|---------|
| List | `GET` | `200` |
| Read one | `GET` | `200`, `404` if absent |
| Create | `POST` | `201` + `Location` header |
| Full replace | `PUT` | `200` / `204` |
| Partial update | `PATCH` | `200` |
| Delete | `DELETE` | `204`, `404` if absent |

`GET` and `DELETE` never have a body. `GET` is always safe and cacheable — no
side effects, ever.

Errors: `400` malformed, `401` unauthenticated, `403` authenticated but not
allowed, `404` absent **or hidden by authz**, `409` state conflict, `422`
semantically invalid, `429` rate-limited, `5xx` our fault only.

## Error shape

One shape across the whole API — clients parse it once:

```json
{
  "error": {
    "code": "INVOICE_ALREADY_FINALIZED",
    "message": "This invoice can no longer be modified.",
    "details": [{ "field": "status", "issue": "must be 'draft'" }],
    "traceId": "01J8..."
  }
}
```

- `code` is a stable, documented, machine-readable enum. Never localize it,
  never reword it — clients branch on it.
- `message` is human-readable and safe to show. No stack, no SQL, no paths.
- `traceId` correlates with logs and is always present.

## Validation

- Validate every inbound payload at the boundary with the shared schema layer
  (`<VALIDATION_LIB>`). Reject unknown fields rather than ignoring them.
- Validation failures return `422` with one `details` entry per field.
- Types are generated from the schema and exported from `packages/shared` so the
  client and server cannot drift.

## Pagination, filtering, sorting

- Cursor pagination by default: `?limit=50&cursor=<opaque>`; response carries
  `{ data, nextCursor }`. `limit` is capped server-side.
- Offset pagination only for admin/reporting endpoints where deep paging is real.
- Filtering is explicit and allowlisted; never build a query from arbitrary
  client-supplied field names.
- Sorting: `?sort=-createdAt` (leading `-` = descending), allowlisted fields only.

## Versioning and compatibility

- Version in the path: `/api/v1/`.
- **Additive changes only** within a version: new optional field, new endpoint,
  new enum value the client may ignore.
- Breaking = removing/renaming a field, tightening validation, changing a status
  code or an error `code`. That needs a new version plus a deprecation window
  announced in `<CHANGELOG_PATH>`.
- Never repurpose an existing field's meaning. Add a new one.

## Cross-cutting

- Every write endpoint is idempotent or accepts an `Idempotency-Key` header.
- Every endpoint declares its authorization rule explicitly — no "inherits from
  the router" assumptions.
- Every endpoint is documented in the generated OpenAPI spec; the spec is built
  from the code, not maintained by hand.
- Log one structured line per request with `traceId`, route, status, duration —
  and never the payload of an authenticated user.
