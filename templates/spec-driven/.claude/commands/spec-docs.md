---
description: Phase 08 — find the docs this change made false, then the ones missing, with the diff that proves it
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Edit Write Bash(git status) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/checks.sh:*)
---

Phase 08 — documentation, for **$slug**.

Read `06-implementation.md`, `07-tests.md`, `02-analysis.md` (contracts) and
`01-reflection.md` (what is user-visible). Phase 07 must be `resolved`.

## The order matters

**First, find what is now false. Only then, what is missing.**

A stale doc actively misleads: someone reads it, believes it, and builds on it.
A missing doc merely fails to help. Teams spend this phase writing new pages
while three old ones quietly describe the behaviour that was just removed —
that is backwards, and it is why documentation stops being trusted.

## Method

1. **Inventory the surfaces.** README, API reference, CHANGELOG, runbooks,
   onboarding, ADRs, docstrings, code samples, error-message text, config
   examples, the `CLAUDE.md` files. Anything a human or a model reads to learn
   how this works.

2. **Pass 1 — now false.** Grep every renamed symbol, changed signature, removed
   flag, altered default, and changed response shape from `02-analysis.md`
   through the doc surfaces. Each hit is either updated or listed with a reason.
   This pass is not optional and it is not the one to rush.

3. **Pass 2 — missing.** One entry per user-visible change from
   `01-reflection.md`. Not per function — per thing a user can now do, or can no
   longer do.

4. **Pass 3 — now dead.** Docs describing behaviour that no longer exists.
   Delete them. A page kept "just in case" is a page someone will find in a year
   and follow.

5. **Verify every claim you write.** A code sample that is not run is a guess
   with syntax highlighting. Run it, or mark it unverified in the artifact.

6. **CHANGELOG entry** in the repo's existing format, written for someone
   upgrading — what breaks, what to do about it, in that order.

7. **Write the expiry condition.** For each doc you touched: what would make it
   false again? That single line is what makes the next maintainer's grep
   possible, and it is the part everyone skips.

## Scope discipline

Only what this change touched. A doc that was already wrong before this spec is
reported as pre-existing, with the `file:line`, and left alone — fixing it here
buries this change's diff inside a documentation cleanup nobody asked to review.

## Output

Write `.claude/specs/$slug/08-docs.md` from `.claude/templates/08-docs.md`.
Commit the doc changes referencing their task ids.

Update `INDEX.md`: phase 08 → `drafted`.

Report back, and nothing else:
- docs that were false, and are now fixed,
- docs added, one line each,
- docs deleted,
- claims you could not verify,
- pre-existing doc problems you deliberately left.

**Stop there.**

Next: `/spec-challenge $slug 08-docs` — optional. Worth running when the change
has a public contract: the challenger reads the doc against the code and finds
where they already disagree.
