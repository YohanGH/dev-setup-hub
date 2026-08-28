---
description: Phase 09 — update the project map and diagram, and name the drift
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Edit Write Task Bash(git status) Bash(git diff:*) Bash(git log:*) Bash(git add:*) Bash(git commit:*)
---

Phase 09 — map, for **$slug**.

Read `02-analysis.md` (the impact map is the raw material) and
`06-implementation.md`. Phase 08 must be `resolved`.

## Two outputs, one canonical

- **`docs/architecture/map.md`** — the canonical, living map of the project. It
  survives this spec. Every spec updates it; none of them owns it.
- **`.claude/specs/$slug/09-map.md`** — this spec's contribution: the **drift**
  (what this change moved) and the evidence behind every edge.

A map that lives inside a spec directory is dead the day the spec closes. A
canonical map that nobody updates is worse than none, because people trust it.
This split is what makes the second failure catchable: the drift table shows
whether the canonical map was actually maintained or merely regenerated.

## Method

1. **Read the previous canonical map first.** If it does not exist, say so — this
   run bootstraps it, and the drift table is the whole map. If it does, the
   output is the difference, not a fresh drawing.

2. **Mermaid, in a markdown file, committed.** Not an exported image. A diagram
   that cannot be diffed will not be maintained, and one that cannot be read in a
   pull request will not be reviewed.

3. **Three levels, no more:**
   - **context** — this system and what it talks to,
   - **modules** — the internal boundaries and who owns what,
   - **the one flow this change touched**, end to end.

   Do not draw everything. A diagram of the whole codebase communicates nothing
   and goes stale on the first commit.

4. **Every edge is evidence.** An arrow means a real import, call, HTTP request,
   queue message or foreign key, with a `file:line`. An arrow drawn because it
   "makes sense architecturally" is the lie that makes the whole diagram
   worthless — and it is the one thing a reader cannot detect.

5. **Every node is a path.** A box named after a concept with no directory or
   module behind it is a wish. Name it or drop it.

6. **Say what you did not draw** and why. A map claiming completeness is not one.

7. **Delegate the sweep if it is wide.** More than ~15 files or several packages:
   `scout` with `context: fork`. You want the map back, not the files.

8. **Write the drift.** What moved, what appeared, what disappeared, and which
   boxes the previous map had that were already fiction before this change.

## Output

Update `docs/architecture/map.md`, and write `.claude/specs/$slug/09-map.md`
from `.claude/templates/09-map.md`. Commit both together.

Update `INDEX.md`: phase 09 → `drafted`.

Report back, and nothing else:
- the drift in five lines,
- edges you could not back with a `file:line`,
- boxes on the old map that were already fiction,
- what you did not draw.

**Stop there.**

Next: `/spec-challenge $slug 09-map` — optional. Worth running when the change
moved a boundary: the challenger opens the edges and finds the ones with nothing
behind them.
