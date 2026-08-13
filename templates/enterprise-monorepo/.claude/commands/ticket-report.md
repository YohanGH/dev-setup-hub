---
description: Write the hand-off report / PR description for a finished ticket
argument-hint: <TICKET-ID>
arguments: ticket
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(git status) Bash(git show:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/preflight.sh:*)
---

Write the hand-off report for **$ticket**.

Follow the `handoff-report` skill and its template exactly.

Build it from evidence only:

- `.claude/tickets/$ticket/scope.md` — what was promised.
- `git diff $(git merge-base HEAD <DEFAULT_BRANCH>)...HEAD` — what was done.
- `.claude/tickets/$ticket/review.md` — what review found, if it ran.
- `.claude/scripts/preflight.sh` — run it now and paste the **real** result into
  the verification table. If it fails, the report says `fail` with the error; do
  not fix and re-run silently.

Write it to `.claude/tickets/$ticket/report.md`.

Lead with deviations: anything in the scope file that did not get built, and
anything built that the scope file never mentioned. If there are none, say so
explicitly.

Then print to me:

- the acceptance-criteria table,
- the verification table,
- the follow-ups list.

Do not commit, push, or open a PR.
