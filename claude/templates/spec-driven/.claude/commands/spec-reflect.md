---
description: Phase 01 — reflect on the problem before any solution, and write what would make this the wrong thing to build
argument-hint: <SLUG>
arguments: slug
disable-model-invocation: true
allowed-tools: Read Grep Glob Write Bash(git log:*) Bash(git show:*) Bash(git diff:*) Bash(gh issue view:*)
---

Phase 01 — reflection, for **$slug**.

Contract: `.claude/conventions/pipeline.md`. Read `.claude/specs/$slug/INDEX.md`
first — the one-line intent there is what you are reflecting on. If it is empty
or is a restatement of the slug, stop and ask.

You are **not** designing a solution. You are establishing that we are about to
solve the right problem, and writing down what would prove us wrong.

## Method

1. **Separate the symptom from the problem.** The intent describes what someone
   noticed. Find the thing underneath it. Quote the evidence: the failing case,
   the log line, the user-visible behaviour, the ticket sentence. If you cannot
   quote anything, that is the finding — say the problem is unevidenced and stop.

2. **Check it does not already exist.** `Grep` the domain nouns, look for a
   sibling implementation, and run `git log -S"<symbol>"` on the code that would
   be touched. A feature half-built two years ago and abandoned is the single
   most common thing this phase catches.

3. **Find the constraint that decides the design.** Not the list of everything
   true about the system — the one or two facts that eliminate options. Backward
   compatibility, a deployed client, a data volume, a deadline, a team that owns
   the other side of the boundary.

4. **Weigh at least three options,** and include the honest ones: *do nothing*,
   and *the smallest thing that removes the symptom*. For each, name what it
   gives up. An option list where one entry is obviously right was written
   backwards from the conclusion — say so and redo it.

5. **Write the falsification conditions.** What would have to be true for this to
   be the wrong thing to build? Make them checkable: a number, a behaviour, a
   fact someone could go and verify today. "If it turns out users do X" is not
   checkable; "if fewer than 5% of sessions reach this screen" is.

6. **Leave the open questions open.** A question you answered by assuming
   something is a decision — move it to Decisions with its rationale, or leave it
   as a question that blocks this phase.

## Output

Write `.claude/specs/$slug/01-reflection.md` from
`.claude/templates/01-reflection.md`. Keep the headings — phase 02 and the
challenger parse them.

Then update `INDEX.md`: phase 01 → `drafted`, and copy any open question into the
Open questions table with `Blocks: 01`.

Report back, and nothing else:
- the problem in one sentence,
- the chosen direction and the option it beat,
- the falsification conditions,
- the open questions that block phase 02.

**Stop there.** Do not open phase 02. Do not touch a source file — this phase
writes one markdown file and nothing else.

Next: `/spec-challenge $slug 01-reflection` — mandatory on this phase.
