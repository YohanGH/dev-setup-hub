---
name: ticket-analysis
description: Analyse a ticket before writing code — read the ticket, map the impacted code, write a scope file. Use when starting work on a ticket, issue, or bug reference such as PROJ-1234, #482, or a pasted ticket description.
when_to_use: Triggered by "start on <ticket>", "what does <ticket> touch", "scope this issue", "where is this implemented", or any request that begins with a ticket identifier.
argument-hint: <TICKET-ID>
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Bash(gh issue view:*) Bash(gh pr list:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/ticket-context.sh:*)
---

# Ticket analysis

Turn a ticket into a **scope file** that a human can check and that survives
context compaction. Never start editing code from a ticket alone — the scope
file is the contract for everything that follows.

The output is `.claude/tickets/$ARGUMENTS/scope.md`. Same input, same shape,
every time — that reproducibility is the point.

## Step 1 — Get the ticket

```bash
.claude/scripts/ticket-context.sh $ARGUMENTS
```

It resolves the ticket from `gh`, from a local `.claude/tickets/<ID>/ticket.md`,
or reports that neither exists. If it reports nothing, **ask for the ticket text
and stop** — do not infer the requirement from the identifier.

Extract, verbatim where possible:

- The **problem** in the reporter's words (not your restatement).
- The **acceptance criteria**. If the ticket has none, write the criteria you
  infer, mark them `INFERRED`, and flag that a human must confirm them.
- Constraints: deadline, compatibility, data volume, affected customers.
- Anything the ticket explicitly puts **out of scope**.

## Step 2 — Locate the code

Search before reading. Cheapest signal first:

1. `Grep` for the domain nouns and error strings from the ticket — not for
   generic words. Search the exact user-visible message if there is one.
2. `Glob` the areas the names suggest; check each package's `CLAUDE.md` for
   where that concern lives.
3. `git log --oneline -S"<symbol>" -- <path>` to find who last changed this and
   why. Read that commit message; it often contains the constraint the ticket
   omits.
4. Only then `Read` — and read the entry point plus its tests before anything
   else. The tests tell you the intended contract.

If the search is broad or spans packages, delegate to the `impact-scout`
subagent so the file dumps stay out of this conversation.

## Step 3 — Map the impact

For every location you will change, record what depends on it. Details and the
checklist are in [`references/impact-checklist.md`](references/impact-checklist.md).
The short version — for each touched symbol, find:

- **Callers** (who breaks if the signature changes)
- **Tests** covering it (which must still pass, which must be added)
- **Contracts** it participates in: API response, shared type, event payload,
  DB column, config key
- **Siblings** — the same pattern implemented elsewhere that a reviewer will
  expect you to have updated too

Anything you find and choose *not* to change is recorded as an explicit
non-goal. Silent omissions are what makes a change look sloppy in review.

## Step 4 — Write the scope file

Write `.claude/tickets/$ARGUMENTS/scope.md` using
[`references/scope-template.md`](references/scope-template.md) exactly — the
review and report steps parse those headings.

Rules for the file:

- Every impacted path is `path/to/file.ts:LINE`, verified, never guessed.
- Every acceptance criterion maps to at least one planned change, or is listed
  as blocked with the reason.
- **Open questions are listed, not resolved by assumption.** A question you
  answered yourself is a decision — record it under Decisions with its rationale.
- Estimate the diff size. If it exceeds ~400 lines, propose a split into
  sequenced tickets and say so before writing any code.

## Step 5 — Confirm, then stop

Report to the user: the plan in five lines, the open questions, and the proposed
split if there is one. **Do not start implementing in the same turn** unless the
user asked for the whole pipeline — the scope file exists to be checked first.

## Anti-patterns

- Reading twenty files "for context" before grepping. It floods the window and
  the read files are mostly irrelevant.
- Writing the scope from the ticket title alone.
- Restating the ticket as the analysis. The value is the code mapping, not the
  paraphrase.
- Marking criteria satisfied because the code "looks right". Trace each one.
