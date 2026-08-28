# The pipeline contract

Every command, agent and hook in this template reads this file. It defines
**where artifacts live**, **what they are called**, and **what a phase status
means**. Change it here and everything downstream follows; change it anywhere
else and the pipeline drifts.

## Two axes of files

The workflow is managed on two files at the steering level, and two files per
phase at the work level.

### Axis 1 — steering (2 files, one per feature)

| File | Nature | Written by |
|------|--------|------------|
| `INDEX.md` | **Mutable state.** Which phase we are in, each phase's status, the challenge verdict, the open questions still blocking. Always reflects *now*. | Every phase command, on entry and on exit |
| `JOURNAL.md` | **Append-only history.** Decisions with their rationale, deviations from an approved artifact, reversals. Never edited, never reordered, never deleted. | Every phase command, plus the reconciliation step |

The split is deliberate. `INDEX.md` answers *where are we*; `JOURNAL.md` answers
*how did we get here, and what did we decide to give up*. One file cannot do
both: a state file that grows a history becomes unreadable, and a history that
gets rewritten stops being evidence.

### Axis 2 — per phase (2 files)

| File | Role | Author |
|------|------|--------|
| `NN-<phase>.md` | The **artifact**. The proposal, then the amended version after reconciliation. This is the phase's output and the input of the next phase. | Builder (AI A) |
| `NN-<phase>.challenge.md` | The **contradiction**. What is wrong, missing, assumed, or unverifiable in the artifact — with a verdict. | Challenger (AI B) |

The artifact is amended in place after reconciliation; the challenge file is
never rewritten. So the artifact always shows the current truth, and the
challenge file preserves what had to be argued to get there.

## Layout

```text
.claude/specs/<slug>/
├── INDEX.md                       steering: state
├── JOURNAL.md                     steering: append-only history
├── 01-reflection.md               + 01-reflection.challenge.md
├── 02-analysis.md                 + 02-analysis.challenge.md
├── 03-tasks.md                    + 03-tasks.challenge.md
├── 04-pseudocode.md               + 04-pseudocode.challenge.md
├── 05-comments.md                 + 05-comments.challenge.md
├── 06-implementation.md           + 06-implementation.challenge.md
├── 07-tests.md                    + 07-tests.challenge.md
├── 08-docs.md                     + 08-docs.challenge.md
├── 09-map.md                      + 09-map.challenge.md
└── 10-recap.md                    + 10-recap.challenge.md
```

`<slug>` is kebab-case and stable for the life of the feature — it appears in
commit footers and in the recap. Use the ticket id when there is one
(`PROJ-1234`), the feature name when there is not (`rate-limit-login`).

## The ten phases

| # | Slug | Question it answers | Definition of done |
|---|------|--------------------|--------------------|
| 01 | `reflection` | What problem are we actually solving, and what would make this the wrong thing to build? | Options weighed, one chosen with a reason, open questions listed as questions |
| 02 | `analysis` | What code does this touch, and what breaks around it? | Every claim is a verified `file:line`; siblings and dynamic references covered |
| 03 | `tasks` | What is the smallest ordered set of verifiable steps? | Each task has an observable done-condition and an owner phase |
| 04 | `pseudocode` | What is the algorithm, before any syntax? | Control flow, data shapes, error paths — no language-specific code |
| 05 | `comments` | Does the intended shape survive contact with the real files? | Intent comments written into the real source files; no logic yet |
| 06 | `implementation` | Does it work, and is it covered where it was written? | Comments filled in; each task committed green **with its unit tests in the same commit** |
| 07 | `tests` | Would we know if it broke? | End-to-end coverage, gaps in the unit tests written in 06, and pasted real run output |
| 08 | `docs` | What did we teach the next person? | Every user-visible change reflected in docs, with the diff that proves it |
| 09 | `map` | What does the project look like now? | Diagram + cartography regenerated, drift from the previous version named |
| 10 | `recap` | What was promised, what was delivered, what was dropped? | Built only from artifacts, diff, and test output — never from memory |

Phases 01–04 write no source code. Phase 05 writes comments only. That boundary
is what makes the early checkpoints cheap to reject.

Unit tests are written in **06**, in the same commit as the code they cover — a
task is not green without them. Phase 07 does not write the first unit test; it
covers the paths that cross process boundaries, hunts the gaps 06 left, and
produces the run output that proves any of it. Docs (08) and the map (09) stay
after implementation: they describe what was built, and describing it before it
exists is how a doc starts lying.

**Challenge is mandatory on 01, 02, 03, 06 and 07.** Three of direction — where a
wrong answer is cheapest to correct — and two of consequence, where a wrong
answer becomes shipped code. On 04, 05, 08, 09 and 10 the challenge is offered
and may be skipped; skipping is recorded in `INDEX.md` as
`challenge: skipped (<reason>)`, never left blank. See
[`conventions/challenge.md`](challenge.md).

## Phase status

Recorded in `INDEX.md`, one per phase:

| Status | Meaning |
|--------|---------|
| `todo` | Not started |
| `drafted` | Artifact written, not yet challenged |
| `challenged` | Challenge file written, verdict pending reconciliation |
| `resolved` | Reconciled and approved by a human — the next phase may start |
| `stale` | An upstream phase changed after this one resolved; re-run or justify |

Only a human moves a phase to `resolved`. That is the checkpoint, and it is the
one thing in this pipeline that is not automated.

## Challenge verdicts

Every `*.challenge.md` ends with exactly one:

| Verdict | Meaning | Consequence |
|---------|---------|-------------|
| `accept` | No finding that changes the next phase | Artifact stands as written |
| `revise` | Findings that change the artifact but not its direction | Builder amends the artifact, journals each change |
| `reject` | The premise is wrong — the next phase would build the wrong thing | Phase is re-run from scratch; the old artifact is journaled, not deleted |

A challenge with no finding is a valid `accept`. A challenger that manufactures
findings to look useful is worse than no challenger — see
[`conventions/challenge.md`](challenge.md).

## Staleness

When a `resolved` phase's artifact is edited, every downstream `resolved` phase
becomes `stale`. The pipeline does not silently re-run them: it marks them and
stops. Re-running is a decision, and it goes in the journal.

This is the rule that keeps the artifacts trustworthy six months later. Without
it, a spec directory becomes a pile of documents that describe three different
versions of the same feature, and no one can tell which.

## Rules that do not bend

1. **The artifact on disk is the source of truth, not the conversation.** Long
   sessions compact. Re-read the file; do not work from a summary of it.
2. **`JOURNAL.md` is append-only.** Correcting a journal entry means adding a
   new one that supersedes it, dated.
3. **No phase starts before the previous one is `resolved`.** The pipeline's
   entire value is that a wrong direction is caught at phase 01, not phase 06.
4. **Unverifiable claims are marked, not smoothed.** `file:line` or it did not
   happen; a pasted command output or the check did not run.
5. **An open question stays open.** A question answered by assumption is a
   decision — it moves to Decisions with its rationale, or it stays a question.
