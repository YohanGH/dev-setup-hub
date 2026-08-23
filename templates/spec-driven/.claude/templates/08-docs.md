---
phase: 08-docs
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
---

# 08 · Documentation — <SLUG>

> First what this change made **false**, then what is **missing**, then what is
> **dead**. In that order — a stale doc misleads, a missing doc merely fails to
> help.

## Surfaces inventoried

Everything a human or a model reads to learn how this works.

| Surface | Path | Touched by this change | Checked |
|---------|------|------------------------|---------|
| README | | yes / no | yes |
| API reference | | | |
| CHANGELOG | | | |
| Runbook / ops | | | |
| Onboarding | | | |
| ADR | | | |
| Docstrings | | | |
| Code samples | | | |
| Error message text | | | |
| Config examples | | | |
| `CLAUDE.md` | | | |

<A surface with `Checked: no` is a surface that may be lying right now. Say why
it was not checked.>

## Pass 1 — made false by this change

The pass that matters. One row per hit from grepping the renamed symbols,
changed signatures, removed flags, altered defaults and changed response shapes
listed in `02-analysis.md`.

| What changed | Doc claim, now false | `file:line` | Fixed | Commit |
|--------------|----------------------|-------------|-------|--------|
| <renamed symbol / changed default / removed flag> | <quote the false sentence> | | yes / **left, because** | `<sha>` |

**Grep coverage.** <The terms you searched, so the next person can re-run it.>

```text
$ git grep -n -e "<term>" -e "<term>" -- <doc paths>
<paste>
```

## Pass 2 — missing

One entry per thing a user can now do, or can no longer do. Not per function.

| User-visible change | Where documented | `file:line` | Commit |
|---------------------|------------------|-------------|--------|
| | | | |

## Pass 3 — now dead

Docs describing behaviour that no longer exists. Deleted, not archived — a page
kept "just in case" is a page someone finds in a year and follows.

| Doc | Described | Action | Commit |
|-----|-----------|--------|--------|
| | | deleted / redirected to `<path>` | |

## CHANGELOG

Written for someone upgrading: what breaks first, what to do about it second.

```markdown
<the entry, in the repo's existing format>
```

## Claims verified

A code sample that was not run is a guess with syntax highlighting.

| Claim / sample | `file:line` | Verified how | Result |
|----------------|-------------|--------------|--------|
| | | ran it / tested / read the code | pass / **unverified** |

## Expiry conditions

The line everyone skips, and the one that makes the next maintainer's grep
possible.

| Doc touched | Goes false again when | Grep for |
|-------------|------------------------|----------|
| `file` | <the change that would invalidate it> | `<term>` |

## Pre-existing, deliberately left

Doc problems that predate this spec. Reported, not fixed — fixing them here
buries this change's diff inside a cleanup nobody asked to review.

| Problem | `file:line` | Why left | Follow-up |
|---------|-------------|----------|-----------|
| | | | |

## Open questions

| # | Question | Blocks | Who can answer |
|---|----------|--------|----------------|
| Q<n> | | | |
