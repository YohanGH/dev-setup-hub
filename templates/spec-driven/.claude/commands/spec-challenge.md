---
description: Run the B side against a phase artifact — findings and a verdict, no edits
argument-hint: <SLUG> <NN-phase>
arguments: slug phase
disable-model-invocation: true
allowed-tools: Read Grep Glob Bash(git log:*) Bash(git diff:*) Bash(git show:*) Task
---

Challenge `.claude/specs/$slug/$phase.md`.

The contract is `.claude/conventions/challenge.md`. It defines the finding
format, the severity scale, the four passes, and the three verdicts. Do not
improvise a different structure — reconciliation parses these headings.

1. Verify the artifact exists and its phase is `drafted` in `INDEX.md`. If it is
   already `challenged` or `resolved`, stop and tell me — a second challenge is
   a decision, not a default.

2. Delegate to the `challenger` subagent with `context: fork`, so the artifact
   and the file reads it triggers stay out of this conversation. The challenger
   gets the artifact path and the repo; it does **not** get my reasoning for
   writing it. That absence is the point.

3. Write the result verbatim to `.claude/specs/$slug/$phase.challenge.md`.
   Do not soften it, do not re-order it, do not drop the nits or the
   "Not checked" section.

4. Update `INDEX.md`: phase → `challenged`, challenge → `done`, verdict → the
   challenger's verdict.

5. Report back:
   - the verdict, in one line,
   - each `blocker` and `major` as one line,
   - the count of minors and nits, not their contents.

**Stop there.** Do not reconcile. Do not amend the artifact. I read the
contradiction before you answer it — a builder that reconciles in the same breath
as it receives the findings will talk itself out of the uncomfortable ones.

> Running the B side outside Claude — a second session on another model, or
> another vendor entirely — is more independent than this subagent and is the
> recommended mode for phases 01 to 03. Paste that model's output into
> `$phase.challenge.md` following the same contract, set its `Challenger.` line
> accordingly, then run step 4 by hand. See `docs/dual-ai-challenge.md`.
