---
phase: 02-analysis
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
verified_against: <git sha>
---

# 02 · Analysis — <SLUG>

> Reality, not plan. Every claim below is a verified `file:line` or is listed
> under [Unverified](#unverified). There is no third category.
>
> Direction being analysed: <the chosen option from `01-reflection.md`>

## Entry points

Where the change starts. Read these and their tests before anything else.

| Entry point | `file:line` | Its tests | Contract the tests state |
|-------------|-------------|-----------|--------------------------|
| | | | |

**Gap between stated and actual.** <Where the tests describe a contract the code
does not honour, or vice versa. This gap is a finding, not a detail.>

## Impact map

One row per symbol that will be touched.

| Symbol | `file:line` | Callers | Tests | Contracts | Siblings |
|--------|-------------|---------|-------|-----------|----------|
| | | | | | |

**Siblings.** <The same pattern implemented elsewhere. If this table is empty,
say how you searched for them — an empty siblings row is usually a search that
was not run, not an absence.>

## Dynamic references

What no compiler and no rename will surface.

| Kind | Value | `file:line` | Breaks if |
|------|-------|-------------|-----------|
| string key / DI token / route / event / flag / reflection | | | |

## Contracts at risk

Anything with a consumer outside this diff.

| Contract | Kind | Consumer | Breaking? | Migration needed |
|----------|------|----------|-----------|------------------|
| | HTTP · shared type · DB column · queue payload · config key · env var | | yes/no | |

## History

`git log -S"<symbol>"` — the last change usually names the constraint the
reflection forgot.

| Symbol | Last change | Date | Constraint it names |
|--------|-------------|------|---------------------|
| | `<sha>` <subject> | | |

## Blast radius

<Five lines. What breaks, where, and how it would show up — a failing test, a 500,
a silent wrong value, a migration that locks a table.>

## Deliberately not changing

Recorded so review does not read these as oversights.

| Code | `file:line` | Why not | Revisit when |
|------|-------------|---------|--------------|
| | | | |

## Size estimate

| | |
|---|---|
| Files touched | |
| Estimated diff | ~<N> lines |
| Over ~400 lines? | yes / no |

**Proposed split.** <If over the threshold: the two or three independently
shippable pieces, in order, each one green on its own. If under, write "not
needed".>

## Unverified

Everything you could not open, run, or confirm. This section existing is what
makes the rest of the document trustworthy.

| Claim | Why unverified | How to verify |
|-------|----------------|---------------|
| | | |

## Open questions

| # | Question | Why it changes the build | Who can answer |
|---|----------|--------------------------|----------------|
| Q<n> | | | |
