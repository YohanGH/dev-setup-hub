# Impact checklist

Run this against every symbol, file, or endpoint the change will touch. The goal
is to find the things a reviewer will know about and you won't.

## 1. Direct dependents

- [ ] **Callers** — `Grep` the symbol name across the repo, not just the package.
      Include dynamic access: string keys, DI tokens, route tables, event names,
      config values, feature flags. Those never show up in a rename.
- [ ] **Re-exports** — is it exported from a package index? Then the blast radius
      is every consumer of the package, not just the direct importers.
- [ ] **Tests** — which suites currently cover it? Which will need to change, and
      does a needed change to an existing assertion mean you're altering a
      documented behaviour?

## 2. Contracts

A contract is anything another system already relies on. Changing one is never
"just a refactor".

- [ ] **HTTP**: request schema, response fields, status codes, error `code`
      values, headers. Additive or breaking? (`conventions/api-design.md`)
- [ ] **Shared types**: a change in `packages/shared` reaches every app in the
      same commit — find the call sites now.
- [ ] **Database**: column type/nullability, index, constraint. Needs a migration?
      Is it expand-migrate-contract? (`rules/migrations.md`)
- [ ] **Async**: queue message shape, event payload, webhook body. Old messages
      may still be in flight — can the new code read the old shape?
- [ ] **Config / env**: a new required variable breaks every environment that
      doesn't have it yet. Default it or stage it.
- [ ] **Persisted state**: cached values, serialized sessions, stored JSON with
      the old shape.

## 3. Siblings and precedent

- [ ] Is this pattern implemented **elsewhere**? Find the other implementations
      (`Grep` a distinctive line, not the symbol name). A fix applied in one of
      three places is a bug report waiting to happen.
- [ ] What does the **existing code in this area** do? Match it. If you are
      deviating from local precedent, that is a decision to record, not a detail.
- [ ] `git log -S"<symbol>"` — has this been changed and reverted before? Read
      that commit. It usually names the constraint the ticket forgot.

## 4. Runtime and operations

- [ ] **Performance**: does the change add a query in a loop, an unbounded fetch,
      a sync call on a hot path? What is the row count in production?
- [ ] **Concurrency**: can two requests race here? Is the write idempotent?
- [ ] **Failure mode**: if the new code throws, what does the user see, and does
      anything end up half-written?
- [ ] **Observability**: will we be able to tell from logs/metrics that this is
      working — or failing — in production?
- [ ] **Rollback**: is reverting the commit sufficient, or does data written by
      the new code need a fix-up?

## 5. Documentation and ownership

- [ ] Does an ADR, README, OpenAPI spec, or `CHANGELOG` entry need to change in
      **this** diff? (`conventions/documentation.md`)
- [ ] Does this cross a team boundary — a package owned by someone else? Name
      them in the scope file; they will be the reviewer.

## Recording the result

Everything found goes into the scope file:

- Things you **will** change → *Impacted code*.
- Things you found and **won't** change → *Related code not being changed*, with
  the reason. This is the section reviewers read first.
- Things you **couldn't determine** → *Open questions*. Never fill a gap with an
  assumption and leave it unmarked.
