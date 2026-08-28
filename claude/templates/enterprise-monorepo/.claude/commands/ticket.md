---
description: Run the full ticket pipeline — scope, implement, review, report — with checkpoints
argument-hint: <TICKET-ID>
arguments: ticket
disable-model-invocation: true
---

Run the full pipeline for **$ticket**. Four phases, each ending in a checkpoint.
Do not cross a checkpoint without my go-ahead.

## Phase 1 — Scope

Run `/ticket-scope $ticket`.

**Checkpoint**: show me the plan, the open questions, and the size estimate.
Wait for my confirmation.

## Phase 2 — Implement

Build against `.claude/tickets/$ticket/scope.md`, in the order its Plan section
lists. While implementing:

- Re-read the scope file rather than working from memory — this session may be
  compacted before you finish.
- Follow the path-scoped rules that load for the files you touch.
- For a bug fix: the failing test comes first, and you show it failing.
- Commit per plan step, each one green. Conventional Commits, ticket in the
  footer.
- If reality contradicts the scope file, **update the scope file and tell me**.
  Do not silently diverge.

**Checkpoint**: report what is built and what remains.

## Phase 3 — Review

Run `/review-scope $ticket`.

Then, for each blocker and major: fix it, or state why it should not be fixed
here. Re-run the review after fixing. `minor` and `nit` findings are listed but
not acted on without my say-so.

**Checkpoint**: show me the verdict and the findings you did not act on.

## Phase 4 — Report

Run `/ticket-report $ticket`.

**Stop.** No push, no PR, no tag. Print the report path and the follow-ups list.

---

If at any phase the work turns out to be materially bigger or different from the
ticket, stop at that point and say so. Finishing a wrong scope carefully is worse
than stopping early.
