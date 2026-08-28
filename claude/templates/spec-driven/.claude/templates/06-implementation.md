---
phase: 06-implementation
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
base_sha: <sha this branch started from>
---

# 06 · Implementation — <SLUG>

> Filled in **per task, as it lands** — not at the end. A record written from
> memory after the fact is fiction, and it is the fiction the recap would inherit.

## Tasks

| Id | Commit | State | Done-condition evidence | Deviated |
|----|--------|-------|-------------------------|----------|
| T1 | `<sha>` | green / blocked / dropped | `<test name>` passes · `<command>` → `<output>` | no / D<n> |
| T2 | | | | |

State is `green` only if the checks ran and passed on that commit. Not "should
pass". Not "passes locally except". If a test was weakened, skipped or deleted to
reach green, that is not green — it is a blocked task with a note.

## Deviations from the plan

The section this file exists for. Silent divergence is how a pipeline becomes
theatre.

### D1 · T<n> · <one line>

**Plan said.** `04-pseudocode.md` T<n> step <k>: <quote>
**Reality.** `file:line` — <what is actually the case>
**Taken.** <what you did instead>
**Cost.** <what this gives up, or what it defers>
**Artifact updated.** `04-pseudocode.md` → <yes, how> · `JOURNAL.md` entry `<date>`

## Unit tests written

One row per task. A task with no test row is a task that is not done.

| Task | Test | Covers | Failure mode from 04 |
|------|------|--------|----------------------|
| T<n> | `<test name>` (`file:line`) | happy path / boundary / error | F<n> · silent-wrong |

**Silent-wrong covered?** yes / no — <if no, name the task it belongs to. This is
the one that must not be deferred to phase 07.>

## Failure-mode coverage against phase 04

| Failure mode (04) | Branch in code | Test | Notes |
|-------------------|----------------|------|-------|
| | `file:line` | `<name>` | |

<Any row without a branch means the code will hit that case and do something
undefined. Any row without a test means nobody will notice when it stops working.>

## Scaffolding removed

```text
$ grep -rn "SCAFFOLD:" <paths>
<paste — must be empty>
```

## Checks

Real output, pasted. Not a summary of it, not "all green".

```text
$ .claude/scripts/checks.sh
<paste>
```

| Check | Result | On commit |
|-------|--------|-----------|
| format | pass / fail / **skip** | `<sha>` |
| lint | | |
| typecheck | | |
| unit tests | | |

A `skip` row means no command is configured for that check — run `/spec-init`.
Skipped is not passed, and a task whose tests are skipped is not green.

## Blocked

| Task | What blocks it | What was tried | Needs |
|------|----------------|----------------|-------|
| T<n> | | | decision / access / upstream fix |

## Not done

| Planned | Why not | Where it went |
|---------|---------|---------------|
| T<n> | | dropped with reason / follow-up / phase 07 |

## Open questions

| # | Question | Blocks | Who can answer |
|---|----------|--------|----------------|
| Q<n> | | | |
