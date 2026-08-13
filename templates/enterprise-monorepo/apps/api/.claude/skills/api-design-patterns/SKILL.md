---
name: api-design-patterns
description: Design an API surface in apps/api — resource modelling, pagination, idempotency, versioning, async operations. Use when designing a new endpoint group, reshaping an existing one, or reviewing an API proposal.
when_to_use: Triggered by "design the API for", "how should this endpoint look", "is this REST-correct", or before implementing a new resource.
allowed-tools: Read Grep Glob
---

# API design patterns

The rules are in [`.claude/conventions/api-design.md`](../../../../../.claude/conventions/api-design.md).
This skill is the *patterns* — the decisions that recur and the trap in each.

## Modelling an action that isn't CRUD

Do not invent a verb endpoint. Model the action as a **sub-resource that
represents the result**:

| Instead of | Use |
|------------|-----|
| `POST /invoices/{id}/finalize` | `POST /invoices/{id}/finalization` |
| `POST /users/{id}/resetPassword` | `POST /users/{id}/password-reset` |
| `POST /orders/{id}/cancel` | `POST /orders/{id}/cancellation` |

It reads the same, but it gives you somewhere to put the *state* of that action
later (`GET /invoices/{id}/finalization`), which a verb endpoint never has.

## Long-running operations

Never hold an HTTP connection open for work measured in seconds.

```
POST /exports              → 202 Accepted, Location: /exports/{id}
GET  /exports/{id}         → { status: "pending" | "done" | "failed", result?, error? }
```

The trap: clients poll. Return a `retryAfter` hint and make `GET` cheap, or you
have built a self-inflicted load test.

## Pagination

Cursor by default: `?limit=50&cursor=<opaque>` → `{ data, nextCursor }`.

The three traps, in the order teams hit them:

1. **The cursor is not opaque.** If clients can construct it, you can never
   change how it works. Encode it and say in the docs that its shape is not part
   of the contract.
2. **No server-side cap on `limit`.** One client sends `limit=1000000`.
3. **Unstable sort.** Paginating by a non-unique column silently skips and
   duplicates rows. Always tie-break on the primary key.

Use offset pagination only for admin screens where someone genuinely jumps to
page 40.

## Idempotency

Every write is idempotent, or it accepts `Idempotency-Key`.

Store the key with the **response** you returned, not just "seen". A retry must
return the same body, not `409`. The client retrying is the client that never
got your first answer — it needs the answer, not an error about having asked.

## Bulk operations

A bulk endpoint that fails atomically on one bad row is unusable; one that fails
silently is dangerous. Return per-item results:

```json
{ "results": [ { "index": 0, "status": "ok", "id": "..." },
               { "index": 1, "status": "error", "error": { "code": "...", "message": "..." } } ] }
```

Status `207` or `200` with per-item status — never a bare `200` that hides three
failures.

## Filtering

Allowlist the filterable fields. Never build a query from client-supplied field
names — that is both an injection surface and an accidental public commitment to
your column names.

## Evolving without breaking

Additive only inside a version. The changes people wrongly believe are safe:

| Looks safe | Actually breaks |
|------------|-----------------|
| Adding a value to a response enum | clients with an exhaustive `switch` |
| Making an optional request field required | every existing caller |
| Tightening validation | payloads that were accepted yesterday |
| Removing a field "nobody uses" | you cannot know this from the server |
| Renaming an error `code` | every client branching on it |

Adding an optional response field and a new endpoint are the only two that are
genuinely free.
