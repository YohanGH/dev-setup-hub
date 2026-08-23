---
description: Phase 04 — write the algorithm before any syntax, error paths first
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Bash(git log:*)
---

Phase 04 — pseudo-code, for **$slug**.

Read `.claude/specs/$slug/03-tasks.md` and `02-analysis.md`. Phase 03 must be
`resolved`; if it is not, stop and say so.

One block per task that has non-trivial logic. A task with no algorithm — a
config change, a mechanical rename — says "no algorithm" and moves on. Padding
this file with pseudo-code for trivial tasks is how it stops being read.

## Method

1. **Data shapes before control flow.** What comes in, what goes out, what must
   stay true throughout. Most algorithms that turn out wrong were wrong about a
   shape — an optional that is never absent in the fixtures, a list that can be
   empty, a timestamp with no timezone.

2. **Error paths get equal space.** For every step that can fail: what fails,
   what the caller sees, what is left behind. The happy path is the part everyone
   writes without help. If your error section is shorter than your happy path,
   you have not finished.

3. **No language syntax.** No imports, no framework names, no decorators, no
   language-specific idioms. Plain indented steps. The moment a framework name
   appears, the phase has stopped being about the algorithm and started being
   about the implementation — and the checkpoint loses its point.

4. **State the invariants.** What is true before, during and after. These become
   assertions in phase 06 and test names in phase 07.

5. **Name the concurrency and ordering assumptions,** even to say there are none.
   "Runs single-threaded, no shared state" is a real answer and a testable one.

6. **Say where the existing code forces a worse shape.** The ideal algorithm and
   the one that fits the code in `02-analysis.md` are often different. Write both
   and say which one you are taking and why — that is exactly the trade the
   challenger should attack.

7. **List what this deliberately does not specify.** Naming, file layout, which
   helper to reuse. Leaving those open is correct; leaving them open *silently*
   means phase 06 will decide them without anyone noticing.

## Output

Write `.claude/specs/$slug/04-pseudocode.md` from
`.claude/templates/04-pseudocode.md`. Every block references its task id from
phase 03.

Update `INDEX.md`: phase 04 → `drafted`.

Report back, and nothing else:
- one line per task block,
- the failure modes you found that phase 03 did not anticipate,
- where the existing code forces a worse shape than the ideal,
- open questions.

**Stop there.** No source file is edited in this phase.

Next: `/spec-challenge $slug 04-pseudocode` — optional on this phase. Worth
running when the algorithm has more than two failure modes, or when getting it
wrong means a migration.
