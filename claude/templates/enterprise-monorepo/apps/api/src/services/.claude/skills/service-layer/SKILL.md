---
name: service-layer
description: Write or change business logic in apps/api/src/services — domain rules, transactions, domain errors. Use when adding or editing a service, use case, or business rule.
allowed-tools: Read Grep Glob Edit Write
---

# Service layer

Loads only while working in `apps/api/src/services/`. This is where the product
actually lives — everything else is plumbing around it.

## The one rule

**A service knows nothing about HTTP.** No `req`, no `res`, no status codes, no
headers. It takes domain inputs, returns domain outputs, and throws domain
errors. That is what makes it testable in milliseconds without a server.

## Shape

```ts
export class InvoiceService {
  async finalize(actor: Actor, invoiceId: InvoiceId): Promise<Invoice> {
    const invoice = await this.invoices.byId(invoiceId);
    if (!invoice) throw new NotFoundError("invoice", invoiceId);
    if (invoice.status !== "draft") throw new InvalidStateError("invoice.finalize", invoice.status);
    // ... the rule this method exists for
  }
}
```

- Dependencies injected through the constructor — never imported as singletons.
  A service you cannot construct in a test is a service nobody will test.
- One public method per use case, named for the use case (`finalize`), not for
  the data (`updateStatus`).
- Domain errors carry structure (`what`, `id`, `state`), not a formatted string.
  The transport layer decides how they become HTTP.

## Transactions and failure

- The transaction boundary is **here**, not in the repository and not in the
  handler. One use case, one transaction.
- If a use case writes twice and can fail in between, either wrap both or make
  the second step idempotent and retryable. Say which in a comment.
- Never swallow an error to "keep going". Partial success is a state the caller
  must be told about.

## Where things must not go

| Not here | Belongs in |
|----------|-----------|
| SQL, query builders, table names | `../db` |
| HTTP status codes, headers, `res` | `../routes` |
| Framework decorators for routing | `../routes` |
| Pure, domain-free helpers | `../utils` |
| Types shared with the frontend | `packages/shared` |

## Tests

Business rules are the **non-negotiable** test target
(`.claude/conventions/testing.md`). For each service method: the rule itself,
its rejection path, and the boundary case. Mock the repository interface you
own — never the database driver.
