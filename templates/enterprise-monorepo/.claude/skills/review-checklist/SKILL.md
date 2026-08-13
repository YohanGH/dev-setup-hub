---
name: review-checklist
description: Review a diff against the project's rubric — correctness, security, tests, conventions — and report findings by severity. Use when reviewing a change, checking a PR, verifying your own work before commit, or when asked "is this ready".
when_to_use: Triggered by "review this", "check my changes", "is this mergeable", "look over the diff", or before producing a ticket report.
allowed-tools: Read Grep Glob Bash(git diff:*) Bash(git log:*) Bash(git show:*) Bash(git status)
---

# Review a diff

The rubric is [`.claude/conventions/review.md`](../../conventions/review.md).
**Read it now** — it defines the severity scale, the five passes, and the exact
output format. This skill is how to apply it without producing noise.

## Get the diff, precisely

```bash
git diff --stat <base>...HEAD      # shape first
git diff <base>...HEAD -- <path>   # then per area
```

Default `<base>` is the merge base with the default branch, not `HEAD~1` — you
are reviewing the branch, not the last commit.

If the diff exceeds what you can review honestly in one pass, say so, review the
highest-risk area first, and name what you skipped. Never skim the rest silently.

## Review in passes, not file by file

File-by-file reading finds typos and misses design defects. Go through the five
passes in `review.md` — scope, correctness, security, tests, conventions —
across the whole diff each time. Most real bugs are found in pass 2 by asking
one question per changed branch: *what input makes this wrong?*

For each hunk that changes behaviour:

1. What did it do before? (`git show <base>:<path>` if the context is unclear.)
2. What input reaches this line?
3. Which of those inputs produces a wrong result now?

If you can't name such an input, there is no finding. Move on.

## Verify, don't speculate

- Trace every claim to a line. A finding without `path:line` is not a finding.
- Before reporting a missing check, `Grep` for it — it is often done in the
  caller or a middleware.
- Before reporting a missing test, look in the test files the diff touched *and*
  the ones it didn't.
- If a defect depends on how a function is called, find a real call site. If
  every call site is safe, downgrade to `minor` and say why.

## What not to report

- Anything the formatter or linter enforces (`conventions/code-style.md` says
  these are already guaranteed).
- Preferences dressed as defects: "I'd extract this", "this could be cleaner".
- Pre-existing issues the diff didn't introduce — unless the diff makes them
  materially worse, in which case say that explicitly.
- The same defect repeated across ten call sites: report it once with the
  pattern and list the locations.

## Output

Exactly the format in `review.md`: findings most-severe first, each with a
concrete failure scenario and the smallest fix; then the verdict line; then
**what was not reviewed**.

Fewer, certain findings beat a long speculative list. A review that reports three
real blockers and admits it skipped the frontend is far more useful than one that
reports twenty maybes.
