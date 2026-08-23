---
description: Phase 02 — map the code this touches and what breaks around it, every claim verified
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Task Bash(git log:*) Bash(git show:*) Bash(git diff:*) Bash(git grep:*)
---

Phase 02 — analysis, for **$slug**.

Read `.claude/specs/$slug/01-reflection.md` and its challenge file. Phase 01 must
be `resolved` in `INDEX.md`; if it is not, stop and say so.

You are mapping reality, not planning work. Every line you write is either a
verified `file:line` or is marked unverified. There is no third category.

## Method

1. **Search before you read.** Grep the domain nouns from the reflection and the
   user-visible strings (error messages, labels, route paths). Do not grep
   generic identifiers — `handler`, `data`, `process` cost a hundred reads and
   answer nothing.

2. **Read the entry point and its tests first.** The tests state the contract the
   code is supposed to honour, which is usually not the contract the code
   actually honours. Both matter, and the gap between them is a finding.

3. **`git log -S"<symbol>"` on every symbol you will touch.** The last change to
   this code usually names the constraint the reflection forgot. Quote the commit
   subject and date.

4. **Build the impact map.** For each symbol: its callers, its tests, the
   contracts it participates in (HTTP response shape, shared type, DB column,
   queue payload, config key, env var), and its **siblings** — the same pattern
   implemented somewhere else. Siblings are what reviewers catch and authors
   miss, every time.

5. **Hunt the dynamic references.** String keys, DI tokens, route tables, event
   names, feature flags, template lookups, reflection, serialized class names. A
   rename never surfaces those and no compiler will tell you.

6. **If the search spans more than one package or you are reading more than ~15
   files, delegate to the `scout` subagent** with `context: fork`. The file
   contents stay out of this conversation; you get the map back. This is not an
   optimisation — a context full of source you already summarised is a context
   that will be compacted before phase 06.

7. **Record what you are deliberately not changing, with the reason.** Silent
   omissions are what make a change look careless in review three weeks later.

8. **Estimate the diff size.** Over ~400 lines, propose a split before phase 03
   turns it into tasks. That proposal is often the most valuable output of this
   whole pipeline.

## Output

Write `.claude/specs/$slug/02-analysis.md` from
`.claude/templates/02-analysis.md`. Every path verified as `file:line` — a path
that reads plausibly is not a verified path, and the challenger will open it.

Update `INDEX.md`: phase 02 → `drafted`, plus any new open question.

Report back, and nothing else:
- the blast radius in five lines,
- the contracts at risk,
- anything you could not verify,
- the size estimate, and the split if it exceeds ~400 lines.

**Stop there.** No source file is edited in this phase.

Next: `/spec-challenge $slug 02-analysis` — mandatory on this phase.
