---
phase: 05-comments
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
tree_state: uncommitted
---

# 05 · Comment-driven scaffolding — <SLUG>

> Comments written into the real source files. No logic, no empty signatures, no
> `TODO: implement` stubs. The tree stays green and uncommitted until phase 06.
>
> The comments are not the deliverable. [Mismatches](#mismatches) is.

## Where the comments went

| Task | File | `line` | Kind | Survives 06? |
|------|------|--------|------|--------------|
| T<n> | `path` | | intent · invariant · failure path · `SCAFFOLD` | yes / no |

`SCAFFOLD:` comments are deleted by phase 06 — they exist to guide the
implementation, not to describe it. Everything else stays and is reviewed as
documentation.

## The comments

Quoted so the challenger reads them without opening ten files, and so review can
diff intent against what was actually built.

### `path/to/file.ext`

```text
// <the comment block, verbatim>
```

**Task.** T<n>
**States.** why / what must be true — <one line>
**Would survive a rewrite of the code below it?** yes / no
<If no, it is a restatement. Delete it now rather than in review.>

## Mismatches

**The output that matters.** Every place the plan and the real files disagreed.
Do not resolve these silently — an adaptation nobody sees is a decision nobody
approved.

| # | Plan said | Code actually | Severity | Resolution |
|---|-----------|---------------|----------|------------|
| M1 | `04-pseudocode.md` T<n>: <claim> | `file:line`: <reality> | blocks 06 / changes shape / cosmetic | adapted here / phase 04 marked stale / open question |

**Already exists.** <Functions, helpers or whole behaviours the plan intended to
write that are already in the codebase, with `file:line`. This row being filled
is this phase paying for itself.>

## Pseudo-code that would not turn into a comment

If a block could not be commented without naming the implementation, phase 04 was
incomplete. Say which — do not invent the missing decision here.

| Block | What was missing | Action |
|-------|------------------|--------|
| T<n> step <k> | | phase 04 → `stale` / open question |

## Coverage against phase 04

| Pseudo-code element | Commented | Where |
|---------------------|-----------|-------|
| Invariants | <n>/<n> | |
| Failure modes | <n>/<n> | |
| Silent-wrong case | yes / no | |

<A failure mode with no comment will not get an implementation branch and will
not get a test. This table is where that gets caught.>

## Tree state

```text
$ git diff --stat
<paste>
```

**Anything other than comments in this diff?** no / <what, and why>

## Open questions

| # | Question | Blocks | Who can answer |
|---|----------|--------|----------------|
| Q<n> | | T<n> | |
