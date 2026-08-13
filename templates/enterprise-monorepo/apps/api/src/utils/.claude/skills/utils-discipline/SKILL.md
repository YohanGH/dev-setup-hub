---
name: utils-discipline
description: Add or change a helper in apps/api/src/utils, or decide whether something belongs there at all. Use when writing a shared helper, a formatter, or any function with no obvious home.
allowed-tools: Read Grep Glob Edit Write
---

# Utils

Loads only while working in `apps/api/src/utils/`. This directory has one
failure mode and it is always the same: it becomes the place where code goes
when nobody decided where it belongs.

> Directory name note: this is `utils`, not `utiles`. Fix the import, don't add
> a second directory.

## Before adding anything, answer this

**"What is this a utility *for*?"**

| Your answer | Where it actually goes |
|-------------|------------------------|
| "For invoices" | next to the invoice service — it is domain logic |
| "For one caller" | in that caller's file, unexported |
| "For the whole company" | `packages/shared` |
| "For nothing in particular, it's generic" | here — if the next rule passes |
| "It calls the database / an API / the clock" | not here. Utils are pure |

If you cannot name what it is for, you are about to create the thing that makes
this directory unreadable in a year.

## Rules

- **Pure and deterministic.** No I/O, no `process.env`, no `Date.now()`, no
  randomness, no logging. A util that reads the clock is a util nobody can test
  without freezing time everywhere.
- **No domain knowledge.** A helper that knows what an invoice is belongs with
  invoices. `formatCurrency` is a util; `formatInvoiceTotal` is not.
- **One concept per file**, named after it. No `helpers.ts`, no `misc.ts`, no
  `index.ts` that re-exports thirty unrelated things.
- **Tested, because it is cheap to test and everything depends on it.** A pure
  function with edge cases and no test is an odd choice given it costs four
  lines.
- **Do not add a dependency for something under ~30 lines of obvious code**
  (`.claude/conventions/code-style.md`), and do not add one here at all if only
  one caller needs it.

## Before writing a new helper

`Grep` for it first. This directory accumulates near-duplicates —
`slugify`/`toSlug`/`makeSlug` — because everyone checks the file they are in
and not the directory. Search for the *behaviour*, not the name you would have
chosen.

If you find a near-duplicate: extend the existing one or delete it, but do not
leave both. Two helpers that differ by one edge case are a bug report waiting
to be filed.
