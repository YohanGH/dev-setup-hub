---
name: type-contracts
description: Add or change a type in apps/api/src/types — and decide whether it belongs here or in packages/shared. Use when defining a domain type, a DTO, or an API response shape.
allowed-tools: Read Grep Glob Edit Write
---

# Types

Loads only while working in `apps/api/src/types/`. The directory is small; the
decision it encodes is not.

## The only question that matters here

**Does the frontend need to know this type?**

| Answer | Where it goes |
|--------|---------------|
| Yes — it crosses the API boundary | `packages/shared` — and the frontend imports it |
| No — it is internal to the API | here |

Getting this wrong is expensive in one direction only: an API response type
declared *here* gets re-declared by hand in `apps/web`, the two drift, and
nothing fails until production. **A type that describes a response body belongs
in `packages/shared`, always.**

## Rules

- Types that describe an HTTP payload are **generated from the schemas** in
  `../schemas` and exported through `packages/shared`. Do not hand-write them
  and do not edit the generated file.
- Internal types stay internal: do not export from the package index something
  only one service uses.
- Prefer branded/nominal ids (`InvoiceId`) over bare `string`. Passing a user id
  where an invoice id belongs is the bug this prevents, and it costs one line.
- Model states as a discriminated union, not as optional fields. `{status:
  "draft"} | {status: "final", finalizedAt: Date}` makes the impossible state
  unrepresentable; `{status: string, finalizedAt?: Date}` invites it.
- No `any`. A genuinely unknown value is `unknown` and gets narrowed at the
  boundary.

## Changing an existing exported type

It is a contract change. Read the `contract-change` skill in `packages/shared`
before touching a type that anything else imports — especially for **widening**
a union, which compiles everywhere and fails on the first unexpected value.
