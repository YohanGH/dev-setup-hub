---
description: Phase 10 — the hand-off, built only from artifacts, diff and pasted output
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Bash(git status) Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/checks.sh:*)
---

Phase 10 — recap, for **$slug**.

## Sources, and only these

Every line you write comes from one of:

- the nine artifacts in `.claude/specs/$slug/` and their challenge files,
- `JOURNAL.md`,
- `git log` and `git diff` against the base sha in `06-implementation.md`,
- a **real** run of `.claude/scripts/checks.sh --all`, pasted.

Not from this conversation, not from memory, not from what you expect to be
true. If a claim has no source in that list, it does not go in — and if it feels
important enough to write anyway, that is the finding: say it is unsourced.

## The failure this phase exists to prevent

A recap that implies completion when work is missing. Everything else in this
pipeline is recoverable; this one is not, because the recap is what people act
on. Someone merges on it, someone plans on it, someone six months from now
reconstructs the reasoning from it.

So: **lead with the deviations.** What was promised and not built, what was built
and never planned. Before the summary, not after it, and not softened.

## Method

1. **Promise vs. delivery, task by task.** `03-tasks.md` against
   `06-implementation.md` and the diff. Every `T<n>` gets a row: delivered,
   partial, dropped. A dropped task keeps its id and states who decided.

2. **Scope drift, both directions.** Every changed file no artifact explains, and
   every planned change absent from the diff. `git diff --name-only` against the
   files named across phases 02 and 06.

3. **Inherit the uncertainty.** Each phase wrote down what it could not verify.
   Collect them — the unverified claims in `02-analysis.md`, the `not verified`
   tests in `07-tests.md`, the unbacked edges in `09-map.md`, the gaps left open,
   the challenges that were skipped and why. This aggregate is the honest answer
   to "how much should I trust this", and it is the reason the earlier phases
   bothered to be honest.

4. **Answer the reflection.** `01-reflection.md` wrote what would make this the
   wrong thing to build. Go back and check each condition against what now
   exists. This is the only place the pipeline closes its own loop.

5. **Open questions that are still open.** Not resolved by having shipped.

6. **Follow-ups**, each one actionable without this conversation: what, where,
   why it was not done here.

## Output

Write `.claude/specs/$slug/10-recap.md` from `.claude/templates/10-recap.md`.
It doubles as the pull request description — write it for someone who was not
here.

Update `INDEX.md`: phase 10 → `drafted`, and set every phase's final status.

Report back: the deviations, the confidence statement, and the recap path.

**Stop.** No push, no PR, no merge, no tag. Printing the recap is the end of the
pipeline.

Next: `/spec-challenge $slug 10-recap` — optional, and the one to skip by
default. Run it when the recap goes somewhere you cannot correct afterwards.
