---
description: Phase 03 — cut the work into the smallest ordered set of verifiable steps
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Bash(git log:*) Bash(git diff:*)
---

Phase 03 — tasks, for **$slug**.

Read `.claude/specs/$slug/02-analysis.md` and its challenge. Phase 02 must be
`resolved`; if it is not, stop and say so.

Derive the tasks from the **impact map**, not from the reflection. The reflection
says what we want; the analysis says what is actually there. Tasks that come from
the first and not the second are the ones that surprise you in phase 06.

## Method

1. **One task = one commit, green on its own.** If a task cannot be committed
   without breaking the build, it is two tasks in the wrong order, or one task
   that needs a compatibility shim — say which.

2. **Every task has an observable done-condition.** A test name, a command and
   the output it must produce, a `file:line` that must exist. Never "implemented
   X" — that is a restatement of the task, and it is unfalsifiable.

3. **Order by what invalidates the design earliest.** The first task should be
   the one most likely to prove the plan wrong. Ordering by comfort — easy
   scaffolding first — hides the risk behind three days of work.

4. **Unit tests belong to the task they cover, in phase 06.** Not a separate row,
   not a later phase. For a bug fix, the failing test is the first thing the task
   produces. A `07` row reading "write unit tests for T1" means T1 was not
   finished — fold it back in.

5. **End-to-end, docs and the map are tasks.** Not afterthoughts appended to the
   last commit. They get rows (owner phases `07`, `08`, `09`), done-conditions,
   and estimates like everything else.

6. **Split anything over ~150 lines of diff.** If it will not split, say why —
   an unsplittable task is a real thing (a generated file, a mechanical rename)
   and naming it as such is different from failing to try.

7. **Name the dependencies, and the ones that are only apparent.** Two tasks that
   both touch a file are not dependent; two tasks where one reads what the other
   writes are.

8. **Write the abandon path.** If we stop after task N, what state is the repo
   in? A plan whose middle is unshippable is a plan that must be finished under
   pressure, which is how the shortcuts get taken.

## Output

Write `.claude/specs/$slug/03-tasks.md` from `.claude/templates/03-tasks.md`.
Task ids are `T1..Tn` and are referenced by every later phase — do not renumber
them after this phase resolves. A dropped task keeps its id and is marked
dropped.

Update `INDEX.md`: phase 03 → `drafted`.

Report back, and nothing else:
- the task list as one line each, in order,
- which task is first and what it invalidates,
- the total estimate against phase 02's,
- anything you had to split or could not.

**Stop there.** No source file is edited in this phase.

Next: `/spec-challenge $slug 03-tasks` — mandatory on this phase.
