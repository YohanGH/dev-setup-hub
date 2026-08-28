---
description: Run the spec-driven pipeline — ten phases, a checkpoint between each
argument-hint: <SLUG> [start-phase]
arguments: slug from
disable-model-invocation: true
---

Run the pipeline for **$slug**, from `$from` if given, otherwise from wherever
`INDEX.md` says we are.

Ten phases. **Do not cross a checkpoint without my go-ahead.** At each one you
stop, report, and wait — that is not a formality, it is the only place a human
decides anything in this pipeline.

| # | Command | Writes | Challenge |
|---|---------|--------|-----------|
| 00 | `/spec-new $slug` | `INDEX.md` + `JOURNAL.md` | — |
| 01 | `/spec-reflect $slug` | `01-reflection.md` | **mandatory** |
| 02 | `/spec-analyze $slug` | `02-analysis.md` | **mandatory** |
| 03 | `/spec-tasks $slug` | `03-tasks.md` | **mandatory** |
| 04 | `/spec-pseudo $slug` | `04-pseudocode.md` | optional |
| 05 | `/spec-comment $slug` | `05-comments.md` + comments in the source | optional |
| 06 | `/spec-implement $slug` | `06-implementation.md` + the code and its unit tests | **mandatory** |
| 07 | `/spec-test $slug` | `07-tests.md` + end-to-end tests | **mandatory** |
| 08 | `/spec-docs $slug` | `08-docs.md` + the docs | optional |
| 09 | `/spec-map $slug` | `09-map.md` + `docs/architecture/map.md` | optional |
| 10 | `/spec-recap $slug` | `10-recap.md` | optional, skip by default |

## The loop, per phase

1. Run the phase command. It stops on its own.
2. **Checkpoint** — I read the artifact.
3. Where the challenge is mandatory: `/spec-challenge $slug <NN-phase>`. It
   writes the contradiction and stops **before** reconciling.
4. **Checkpoint** — I read the challenge.
5. Reconcile: amend the artifact for each `blocker` and `major`, or write why
   not. Journal every amendment with the finding id it answers. List the ones
   left untouched.
6. I set the phase to `resolved` in `INDEX.md`. Only I do that.

## Rules that hold across the whole run

- **No phase starts before the previous one is `resolved`.** The entire value of
  this pipeline is that a wrong direction is caught at 01, not at 06.
- **Re-read the artifacts; do not work from memory.** This session will be
  compacted before phase 10. Files on disk survive that; summaries do not.
- **If reality contradicts an approved artifact, update the artifact and say so.**
  Silent divergence is how a pipeline becomes theatre.
- **Editing a `resolved` artifact marks every downstream `resolved` phase
  `stale`.** Do not re-run them on your own — mark them, stop, and tell me.
- **Never weaken a check to move forward.** No skip, no loosened assertion, no
  `--no-verify`. A blocked phase is a result; a green one that was bought is not.
- **Skipping an optional challenge is fine. Skipping it silently is not** —
  `INDEX.md` records `challenge: skipped (<reason>)`.

## When to stop the whole run

If at any phase the work turns out to be materially bigger or different from what
`01-reflection.md` describes, **stop there and say so**. Do not carry on and
mention it in the recap.

Finishing a wrong spec carefully is worse than abandoning it at phase 02, because
the artifacts make it look considered.

## At the end

Print the recap path and the follow-ups. **No push, no PR, no merge, no tag** —
those are mine.
