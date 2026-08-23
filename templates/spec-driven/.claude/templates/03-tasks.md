---
phase: 03-tasks
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
---

# 03 · Tasks — <SLUG>

> Derived from the impact map in `02-analysis.md`, not from the reflection.
> Ids `T1..Tn` are permanent: every later phase, commit footer and recap line
> references them. Never renumber. A dropped task keeps its id and is marked
> dropped.

## Order

**First task: <T?>**, because <what it proves or disproves>. If it fails, the
design in `01-reflection.md` is wrong and we have spent one task finding out.

<Two lines on the ordering principle. If the order is "easiest first", say so and
justify it — comfort-ordering hides risk behind days of work.>

## The tasks

| Id | Task | Done when (observable) | Owner phase | Depends on | Est. |
|----|------|------------------------|-------------|------------|------|
| T1 | | `<test name>` passes / `<command>` prints `<x>` / `file:line` exists | 06 | — | ~<n> lines |
| T2 | | | 06 | T1 | |
| T3 | <end-to-end path> | | 07 | T2 | |
| T4 | <doc surface> | | 08 | T2 | |
| T5 | <diagram / map> | | 09 | T2 | |

Owner phase: `06` implementation **and its unit tests** · `07` end-to-end and
coverage gaps · `08` docs · `09` map.

Two rules on this table:

- A done-condition that restates the task ("X is implemented") is not a
  done-condition.
- A `06` task carries its own unit tests. Do not create a separate `07` row for
  "write unit tests for T1" — that row is a symptom of a T1 that was not
  finished.

## Dependencies

Real ones only — two tasks touching the same file are not dependent; one reading
what the other writes is.

| Task | Blocked by | Nature of the dependency |
|------|------------|--------------------------|
| | | data / contract / ordering / migration |

## Splits

| Original | Split into | Why |
|----------|-----------|-----|
| | | |

**Would not split.** <Task, and why it is genuinely atomic — a generated file, a
mechanical rename. Different from having failed to try.>

## Abandon path

If we stop after each task, what state is the repo in?

| Stopped after | Repo state | Shippable? | Cleanup needed |
|---------------|------------|------------|----------------|
| T1 | | yes / no | |
| T2 | | | |

<If any row says "no", say what would make it yes. A plan whose middle is
unshippable has to be finished under pressure, and that is where the shortcuts
come from.>

## Not tasks

Things that look like work in this change and are not part of it.

| Looks like a task | Why it is not | Where it went |
|-------------------|---------------|---------------|
| | | non-goal / follow-up ticket / already exists |

## Estimate

| | |
|---|---|
| Tasks | <n> |
| Total estimate | ~<N> lines |
| Phase 02 estimate | ~<N> lines |
| Divergence | <if the two differ by more than ~30%, explain which one is wrong> |

## Open questions

| # | Question | Blocks | Who can answer |
|---|----------|--------|----------------|
| Q<n> | | T<n> | |
