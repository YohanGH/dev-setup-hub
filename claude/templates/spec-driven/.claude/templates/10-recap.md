---
phase: 10-recap
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
base_sha: <sha>
head_sha: <sha>
---

# 10 · Recap — <SLUG>

> Built from the artifacts, the diff and pasted command output. Nothing here
> comes from memory. Doubles as the pull request description — written for
> someone who was not here.

## Deviations

**First, before the summary.** What was promised and not built, what was built
and never planned. Not softened.

| # | Deviation | Kind | Decided by | Journal |
|---|-----------|------|------------|---------|
| | | promised-not-built / built-not-planned / changed-shape | | `<date>` |

<If this table is empty, say "none" explicitly. An empty section reads as an
omission; "none" reads as a claim, which is what it is.>

## What this does

<Three lines. What a user can now do, or can no longer do. Not the
implementation.>

## Promise vs. delivery

`03-tasks.md` against `06-implementation.md` and the diff.

| Task | Promised | State | Evidence | Commit |
|------|----------|-------|----------|--------|
| T1 | | delivered / partial / **dropped** | `<test>` passes · `<command>` → `<output>` | `<sha>` |

**Dropped tasks.** <Id, why, who decided. A dropped task keeps its id forever.>

## Scope drift

Both directions.

```text
$ git diff --name-only <base_sha>..HEAD
<paste>
```

| Direction | File / change | Explained by | Note |
|-----------|---------------|--------------|------|
| changed but unplanned | `path` | no artifact | |
| planned but absent | | `03-tasks.md` T<n> | |

## Answering the reflection

`01-reflection.md` wrote what would make this the wrong thing to build. The only
place this pipeline closes its own loop.

| Condition from 01 | Still true? | Evidence |
|-------------------|-------------|----------|
| <if this is true, the direction is wrong> | no / **yes** | |

<A `yes` row does not necessarily block the merge. It does have to be said out
loud, here, where someone can act on it.>

## Confidence

Inherited from each phase's own honesty section. This is the answer to "how much
should I trust this", and it is why the earlier phases bothered.

| Source | What is not certain | Impact if wrong |
|--------|---------------------|-----------------|
| `02-analysis.md` → Unverified | | |
| `07-tests.md` → `not verified` (<n> of <n> tests) | | |
| `09-map.md` → unbacked edges | | |
| Gaps left open in `07-tests.md` | | |
| Challenges skipped | <phase>, because <reason> | |

**In one sentence.** <What you would not bet on, and why.>

## Checks

```text
$ .claude/scripts/checks.sh --all
<paste — the real run, at head_sha>
```

| Check | Result |
|-------|--------|
| format · lint · typecheck · tests | |

<A failed check is reported as `fail` with its error. A recap that reports a
failing suite as "mostly passing" is the one failure mode that makes every other
artifact in this directory worthless.>

## Still open

| # | Question | Why shipping did not answer it | Who can |
|---|----------|-------------------------------|---------|
| Q<n> | | | |

## Follow-ups

Actionable without this conversation.

| What | Where | Why not here | Size |
|------|-------|--------------|------|
| | `file:line` / new ticket | | |

## Artifact trail

| Phase | Status | Challenge | Verdict |
|-------|--------|-----------|---------|
| 01 reflection … 09 map | | | |

<Copied from `INDEX.md` at close. Anything not `resolved` is named here with its
reason.>
