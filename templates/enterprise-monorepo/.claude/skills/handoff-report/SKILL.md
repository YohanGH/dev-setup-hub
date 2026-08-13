---
name: handoff-report
description: Write the hand-off report for a finished ticket — what changed, why, how it was verified, what is left. Use when a ticket is done, before opening a PR, or when asked to summarise a change for a reviewer.
when_to_use: Triggered by "write the report", "summarise what you did", "prepare the PR description", or at the end of the ticket pipeline.
argument-hint: <TICKET-ID>
allowed-tools: Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(git status) Bash(git show:*)
---

# Hand-off report

The artifact a reviewer reads **instead of** re-deriving your work. It goes to
`.claude/tickets/$ARGUMENTS/report.md` and doubles as the PR description.

Build it from evidence, not memory: the scope file, the actual diff, and the
actual command output.

## Inputs

| Input | Where |
|-------|-------|
| What was promised | `.claude/tickets/$ARGUMENTS/scope.md` |
| What was done | `git diff <base>...HEAD` |
| What was found | `.claude/tickets/$ARGUMENTS/review.md` (if `/review-scope` ran) |
| What passed | the real output of `.claude/scripts/preflight.sh` |

If the scope file is missing, run `/ticket-scope $ARGUMENTS` first — a report
with nothing to compare against is just a diff summary.

## Template

```markdown
# <TICKET-ID>: <title>

## What changed
<Three sentences max, in the reviewer's terms. The behaviour, not the files.>

## Why
<The problem from the ticket. Link it.>

## Acceptance criteria

| # | Criterion | Status | Evidence |
|---|-----------|--------|----------|
| 1 | <from scope.md> | met / partial / not met | `path/file.ts:42` or test name |

## Changes

| Path | What and why |
|------|--------------|
| `apps/api/src/x.ts` | <one line> |

## Deliberately not done
<From the scope file's out-of-scope list, plus anything dropped along the way
and the reason. This section is never empty in a real change — if it is, say so.>

## Verification

| Check | Command | Result |
|-------|---------|--------|
| Format/lint | `<cmd>` | pass / fail |
| Typecheck | `<cmd>` | pass / fail |
| Tests | `<cmd>` | <n> passed, <n> skipped |
| Manual | <what you actually exercised> | <what you observed> |

## Risk & rollback
- **Risk**: <what breaks if this is wrong>
- **Detection**: <how it would show up>
- **Rollback**: <revert suffices | data fix needed, described>

## Follow-ups
- [ ] <thing that should be a ticket, with why it wasn't done here>
```

## Rules

- **Report what happened, not what should have happened.** If a check failed, the
  Result column says `fail` with the error. If you skipped a check, say so.
- Never write "tested locally". Name the command and paste the counts.
- Never claim a criterion is met without evidence you can point at.
- Deviations from the scope file are the most important content in the report —
  lead with them if there are any.
- If work is incomplete, the report says exactly what remains and what blocks it.
  A report that implies completion when work is missing is the one failure mode
  that makes the whole pipeline untrustworthy.
