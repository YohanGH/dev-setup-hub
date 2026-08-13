---
name: contract-change
description: Change a shared type, exported function, or generated API contract safely across every consumer. Use when editing anything exported from packages/shared, or when a change in one package must land in another at the same time.
when_to_use: Triggered when work touches packages/shared, or when a rename or signature change would span apps/api and apps/web.
allowed-tools: Read Grep Glob Edit Bash
---

# Changing a shared contract

Everything in this package is consumed by at least two others. The failure mode
is not a compile error — those are cheap and loud. It is the **silent** one:
data already written, a client already deployed, a message already queued.

## 1. Classify the change first

| Change | Class | What it needs |
|--------|-------|---------------|
| Add an optional field | additive | nothing special |
| Add a required field | breaking | a default, or every producer updated first |
| Rename a field | breaking | new field + read both + migrate + remove, across deploys |
| Narrow a type (`string` → union) | breaking | existing values may not fit — check the data |
| Widen a type (union → `string`) | breaking **for consumers** | every `switch` over it now has an unhandled case |
| Remove anything | breaking | deprecate first, remove in a later release |

Widening is the one that gets missed. It compiles everywhere and fails at the
first unexpected value.

## 2. Find every consumer — including the invisible ones

```bash
grep -rn "<symbol>" --include="*.ts" apps/ packages/ scripts/
```

Then the ones grep on the symbol will not find:

- Dynamic access: string keys, DI tokens, route tables, event names, config keys.
- **Persisted data**: rows, cached JSON, stored sessions written with the old
  shape. Code deploys; data does not.
- **In-flight messages**: a queue may hold the old payload for hours.
- **Deployed clients**: a browser tab open since before the release still runs
  the old bundle.

If any of the last three apply, the change must be **tolerant of both shapes for
one release**, not just correct after deploy.

## 3. Sequence it

For anything breaking, three steps across separate deploys:

1. **Expand** — add the new shape alongside the old. Readers accept both.
2. **Migrate** — update producers, backfill stored data.
3. **Contract** — remove the old shape once nothing writes or holds it.

Collapsing this into one commit is what causes the outage. The same shape as
`.claude/rules/migrations.md`, for the same reason.

## 4. Land it as one reviewable change

- Update the shared type and **every call site in the same commit**. A commit
  that leaves the repo not typechecking is not a valid step.
- Regenerate rather than hand-edit anything generated from the API schemas.
- Add a test at the boundary asserting the old shape is still accepted, if you
  are in the expand phase.

## 5. Record it

In the scope file and the PR: what the old shape was, what the new one is, which
phase this commit is, and what the follow-up ticket for the contract step is. A
reviewer cannot verify an expand/migrate/contract sequence they cannot see.
