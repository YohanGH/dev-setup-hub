---
phase: 07-tests
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
---

# 07 · Tests — <SLUG>

> The unit tests were written in phase 06, in the commit of the task they cover.
> This phase adds end-to-end coverage, hunts the gaps 06 left, and produces the
> run output.
>
> The question here is not *does it work*. It is **would we know if it broke?**

## End-to-end

One per user-visible path from `01-reflection.md`, not per function. These are
the tests that must still make sense after a refactor.

| Test | Path covered | Boundaries actually crossed | Commit |
|------|--------------|------------------------------|--------|
| `<name>` (`file:line`) | | HTTP · DB · queue · filesystem · third-party | `<sha>` |

<If every collaborator in a row is mocked, it is a unit test with more setup.
Say so and either promote it or drop the claim.>

## What each test would catch

The column that separates coverage from decoration. Name the change that makes
the test fail. If you cannot, the test asserts nothing.

| Test | Deleting / breaking this makes it fail |
|------|----------------------------------------|
| `<name>` | |

## Gaps closed

| Source | Gap | Test added | Commit |
|--------|-----|------------|--------|
| `04-pseudocode.md` failure mode F<n> | | `<name>` | `<sha>` |
| silent-wrong case | | | |
| boundary: empty / one / many / max / null | | | |
| `02-analysis.md` contract at risk | | | |
| sibling pattern at `file:line` | | | |

## Gaps left open

Deliberate, with a reason. An unlisted gap is the one that bites.

| Gap | Why left | Risk if it breaks | Follow-up |
|-----|----------|-------------------|-----------|
| | | | |

## Fail-for-the-right-reason

A test that passes against broken code is worse than no test. Breaking the code
and watching the test go red is the only way to find one.

**Recommended, not blocking.** It costs a round trip per test. What is not
optional is the honesty of this table: every new test gets a row, and a test you
did not check is `not verified` — never blank, never `yes`.

| Test | Code broken how | Failed as expected | Restored |
|------|-----------------|--------------------|----------|
| `<name>` | <the one-line change you made> | yes / **no** / `not verified` | yes |

- A **`no`** row is a finding, not a detail — that test asserts something other
  than what its name says.
- A **`not verified`** row is not a defect. It is a known limit on how much this
  suite proves, and it travels: into the challenge, and into the confidence
  statement in `10-recap.md`.

| | |
|---|---|
| New tests | <n> |
| Verified to fail correctly | <n> |
| `not verified` | <n> |

## Flakiness

New end-to-end tests, run three times.

| Test | Run 1 | Run 2 | Run 3 | Verdict |
|------|-------|-------|-------|---------|
| `<name>` | pass | pass | pass | stable |

<Two out of three is a failing test that has not been diagnosed yet, not a
"mostly passing" one.>

## Full battery

Real output. Not a summary, not "all green".

```text
$ .claude/scripts/checks.sh --all
<paste>
```

| Check | Result | Notes |
|-------|--------|-------|
| format | pass / fail / skip | |
| lint | | |
| typecheck | | |
| tests | | <n> passed / <n> failed / <n> skipped |

## Pre-existing failures

Failures this change did not introduce. Prove it — `git stash`, re-run, restore
— and say that you checked.

| Failure | Pre-existing | How proven | Owner |
|---------|--------------|------------|-------|
| | yes | `git stash` + re-run at `<sha>` | |

## Nothing was weakened

| | |
|---|---|
| Tests skipped or deleted to reach green | none / **<which, and why that is not a blocker>** |
| Assertions loosened | none / |
| Lint rules disabled | none / |
| `--no-verify` used | no / |

<Anything other than "none" here is a `blocker` for the challenge, always.>

## Open questions

| # | Question | Blocks | Who can answer |
|---|----------|--------|----------------|
| Q<n> | | | |
