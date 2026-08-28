<!-- Language: English · [Français](fr/ticket-workflow.md) -->

# The ticket workflow

Most people already do this by hand: read the ticket, hunt for the code it
touches, check what else depends on it, work, then write up what changed. It
works, and it is different every time — different depth, different omissions,
nothing to compare against afterwards.

This is that same workflow made **reproducible**: fixed steps, fixed artifacts,
evidence instead of recollection.

Implementation:
[`templates/enterprise-monorepo`](../templates/enterprise-monorepo/).

## The pipeline

```text
/ticket-scope PROJ-1234    read ticket · map code · map impact   → scope.md
      ↓  checkpoint: you approve the plan
   implement               against the scope file                → commits.log
      ↓  checkpoint
/review-scope PROJ-1234    diff vs scope + rubric                → review.md
      ↓  checkpoint
/ticket-report PROJ-1234   hand-off report / PR description      → report.md
```

`/ticket PROJ-1234` runs all four with a stop between each.

Artifacts land in `.claude/tickets/PROJ-1234/`.

## Why files, not conversation

Three concrete reasons, not aesthetics:

1. **Long sessions compact their context.** A plan that exists only in the
   conversation can disappear mid-task. A file on disk does not — and Claude
   re-reads it instead of reconstructing it from a summary.
2. **A checkpoint needs something to check.** "Here's my plan" in chat scrolls
   away. `scope.md` can be read, corrected, and diffed against the result.
3. **The report becomes verifiable.** `review.md` and `report.md` are written
   against `scope.md` and the actual diff, so "did this do what it promised" is
   a comparison rather than a judgement call.

`commits.log` is written by a **hook**, not by the model — it is the one artifact
that cannot be misremembered.

## Step 1 — Scope

`/ticket-scope <ID>` resolves the ticket (local file, then `gh`), maps the code,
and writes `scope.md`. It **stops before editing anything**.

What makes the scoping worth its cost:

- **Search before reading.** Grep domain nouns and user-visible error strings,
  not generic identifiers. Read the entry point and its tests first — the tests
  state the intended contract.
- **`git log -S"<symbol>"`.** The last change to this code usually names the
  constraint the ticket forgot.
- **The impact map.** For each symbol touched: callers, tests, contracts (HTTP
  response, shared type, DB column, queue payload, config key), and *siblings* —
  the same pattern implemented elsewhere. The last one is what reviewers catch
  and authors miss.
- **Dynamic references.** String keys, DI tokens, route tables, event names,
  feature flags. A rename never surfaces those.

Two properties of the output matter more than completeness:

- **Related code deliberately *not* changed is recorded, with the reason.**
  Silent omissions are what make a change look careless in review.
- **Open questions stay open.** A question resolved by assumption is a decision;
  it goes under Decisions with its rationale, or it stays a question.

If the estimate exceeds ~400 lines of diff, the step proposes a split before any
code is written. That is usually the most valuable output of the whole pipeline.

## Step 2 — Implement

Against the scope file, in the order its plan lists. One commit per step, each
one green.

The rule that keeps it honest: **if reality contradicts the scope file, update
the scope file and say so.** Silent divergence is how a pipeline becomes theatre.

## Step 3 — Review

`/review-scope <ID>` runs `context: fork` into the `code-reviewer` subagent, so
the whole-branch diff never enters your conversation — you get findings and a
verdict.

It does two things a generic review does not:

- **Criterion by criterion**: each acceptance criterion → met / partial / not
  met, with the `file:line` or test name that proves it. No evidence = not met.
- **Scope drift**: every changed file the scope doesn't explain, and every
  planned change absent from the diff.

The rubric lives in `.claude/conventions/review.md`, checked into the repo, so
severity means the same thing to everyone. Findings need a **concrete failure
scenario** — inputs or state that produce the wrong result — or they are nits.

Reviewer gets `disallowedTools: Edit, Write`. A reviewer that can fix will fix,
and then it can no longer see the code.

## Step 4 — Report

`/ticket-report <ID>` builds the hand-off from evidence only: the scope file, the
diff, `review.md`, `commits.log`, and a **real** preflight run pasted in.

It leads with deviations — what was promised and not built, what was built and
never planned. If a check failed, the report says `fail` with the error.

The failure mode this guards against is the only one that makes the whole system
untrustworthy: a report that implies completion when work is missing.

## Adapting it

| Your setup | Change |
|------------|--------|
| Jira / Linear instead of GitHub | `.claude/scripts/ticket-context.sh` — one script, one resolution function |
| Different ticket key format | `CC_TICKET_PATTERN` in `lib/common.sh` |
| Ticket artifacts in git | commit `.claude/tickets/`; otherwise gitignore it |
| No review step | drop `/review-scope`; keep scope and report — they carry most of the value |
| Several tickets at once | `claude --bg "@ticket-analyst scope PROJ-1234"` per ticket, then `claude agents` |

## What this is not

It is not a way to hand over judgement. Every checkpoint exists because a human
decides: is this the right scope, is this the right implementation, is this
mergeable. The pipeline removes the variance in *how the work is prepared and
reported* — not the decision about whether it is correct.

## See also

- [choosing-a-primitive.md](choosing-a-primitive.md) — why each step is a
  command, a skill, or an agent
- [agents-and-autonomy.md](agents-and-autonomy.md) — running steps in the
  background
- [hooks-and-automation.md](hooks-and-automation.md) — the gate around the
  pipeline
