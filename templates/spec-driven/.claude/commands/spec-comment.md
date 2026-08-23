---
description: Phase 05 — write intent comments into the real source files, no logic yet
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Edit Write Bash(git diff:*) Bash(git status) Bash(git log:*)
---

Phase 05 — comment-driven scaffolding, for **$slug**.

Read `.claude/specs/$slug/04-pseudocode.md`, `03-tasks.md` and `02-analysis.md`.
Phase 04 must be `resolved`; if it is not, stop and say so.

This is the first phase that opens a source file. You write **comments only** —
no statements, no signatures you then leave empty, no `TODO: implement` stubs
that break the build. The working tree stays green and stays uncommitted.

The value of this phase is not the comments. It is what writing them into the
*real* files tells you: that the function you planned already exists under
another name, that the file has no sensible place for this, that the pseudo-code
assumed a boundary the code does not have. That mismatch is cheap here and
expensive in phase 06.

## What a comment must be

Each block answers **why** and **what must be true**. Never what the next line
does.

```text
good:  // Retries only on 5xx — a 429 here means the tenant is over quota and
       // retrying makes it worse. Caller is expected to surface it.
bad:   // Loop over the items and call the handler
```

The test: if the comment would still be true after the code is rewritten, it is
an intent comment. If it would have to be rewritten with the code, it is a
restatement — delete it now, not in review.

## Method

1. **Place the comment where the code will go**, inside the existing structure.
   Do not create new files unless `03-tasks.md` says a new file is a task.

2. **One block per invariant and per failure mode** from the pseudo-code. The
   error paths get comments before the happy path does — that ordering is the
   whole discipline.

3. **If you cannot write a comment without naming the implementation,** the
   pseudo-code was incomplete. Stop, say which block, and mark phase 04 `stale`
   rather than inventing the missing decision here.

4. **Record every mismatch** you hit between the plan and the real files. This is
   the output that matters. Do not quietly adapt the plan — an adaptation nobody
   sees is a decision nobody approved.

5. **Mark what is scaffolding.** Some comments exist to guide phase 06 and should
   not survive it. Prefix those `// SCAFFOLD:` so 06 can delete them by grep, and
   so review can tell a leftover from an intent comment.

6. **Do not commit.** The tree stays dirty until phase 06 commits per task, green,
   with its tests. A comment-only commit either breaks the build or produces a
   commit that says nothing — both are worse than a dirty tree for one phase.

## Output

Write `.claude/specs/$slug/05-comments.md` from
`.claude/templates/05-comments.md`: the file-by-file map, the comments quoted,
the mismatches, and what is scaffolding.

Update `INDEX.md`: phase 05 → `drafted`.

Report back, and nothing else:
- `git diff --stat` (comments only — say it if anything else moved),
- every mismatch between the plan and the real files,
- any pseudo-code block you could not turn into a comment, and why.

**Stop there.** No logic. Not one statement.

Next: `/spec-challenge $slug 05-comments` — optional. Worth running when the
mismatch list is long: a plan that needed adapting in five places usually needed
rejecting in one.
