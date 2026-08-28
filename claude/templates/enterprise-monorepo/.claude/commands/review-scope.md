---
description: Review the current branch against a ticket's scope file and the project rubric
argument-hint: <TICKET-ID>
arguments: ticket
context: fork
agent: code-reviewer
effort: high
disable-model-invocation: true
---

Review the current branch for ticket **$ticket**.

Inputs, in this order:

1. `.claude/tickets/$ticket/scope.md` — what was promised. If it is missing, say
   so and review against the ticket alone, flagging that the scope was never
   recorded.
2. `git diff $(git merge-base HEAD <DEFAULT_BRANCH>)...HEAD` — what was done.
3. `.claude/conventions/review.md` — the rubric. Read it; it defines severity,
   the five passes, and the output format.

Apply the `review-checklist` skill.

Two things this review must do that a generic review does not:

- **Criterion by criterion**: for each acceptance criterion in `scope.md`, state
  met / partial / not met, with the `file:line` or test name that proves it. A
  criterion with no evidence is `not met`.
- **Scope drift**: list every changed file that the scope file does not explain,
  and every planned change in the scope file that is absent from the diff.

Write the result to `.claude/tickets/$ticket/review.md` in the exact format from
`conventions/review.md`, and return to me:

- the verdict line,
- blockers and majors only,
- what you did not review.

Do not fix anything. Findings only — I decide what gets changed.
