<!-- Language: English · [Français](../../docs/fr/template-spec-driven.md) -->

# Template — spec-driven

A Claude Code setup where **every phase of the work writes a durable file**, and
a second model attacks each one before a human approves it.

Ten phases, from "what problem is this really" to the hand-off. Each produces an
artifact on disk. Each stops.

It is the opposite trade from moving fast: it costs more per feature, and it
makes the reasoning survive the session, the compaction, and the six months after
you stop remembering any of it.

## When this is worth it

| Worth it | Not worth it |
|----------|--------------|
| The cost of building the wrong thing is high | A typo fix, a copy change, a dependency bump |
| Someone else will maintain this | You will delete it next week |
| The decision needs to be defensible later | The decision is obvious |
| The work spans more sessions than a context window | It fits in one sitting |

Do not run ten phases on a two-line change. The pipeline's honesty depends on
people believing it is worth filling in, and nothing destroys that faster than
being made to write a reflection on a version bump.

## The two axes of files

The whole design is in this split.

**Steering — two files per feature:**

| File | Nature |
|------|--------|
| `INDEX.md` | Mutable state. Which phase, what status, what verdict, what is still blocking. Always *now*. |
| `JOURNAL.md` | Append-only history. Decisions, deviations, reversals — never edited, never reordered. |

One file cannot do both. A state file that grows a history becomes unreadable; a
history that gets rewritten stops being evidence.

**Work — two files per phase:**

| File | Author |
|------|--------|
| `NN-<phase>.md` | The builder (model A). Amended in place after reconciliation. |
| `NN-<phase>.challenge.md` | The challenger (model B). Never rewritten. |

So the artifact always shows the current truth, and the challenge file preserves
what had to be argued to get there — including the objection that was raised,
considered, and overruled.

## The ten phases

| # | Command | Answers | Challenge |
|---|---------|---------|-----------|
| 01 | `/spec-reflect` | What problem is this really, and what would make it the wrong thing to build? | **mandatory** |
| 02 | `/spec-analyze` | What code does this touch, and what breaks around it? | **mandatory** |
| 03 | `/spec-tasks` | What is the smallest ordered set of verifiable steps? | **mandatory** |
| 04 | `/spec-pseudo` | What is the algorithm, before any syntax? | optional |
| 05 | `/spec-comment` | Does the intended shape survive contact with the real files? | optional |
| 06 | `/spec-implement` | Does it work, and is it covered? | **mandatory** |
| 07 | `/spec-test` | Would we know if it broke? | **mandatory** |
| 08 | `/spec-docs` | What did this change make *false*? | optional |
| 09 | `/spec-map` | What does the project look like now? | optional |
| 10 | `/spec-recap` | What was promised, delivered, dropped? | skip by default |

`/spec <slug>` runs them in order with a stop between each.

Phases 01–04 write no source code. Phase 05 writes comments only. That boundary
is what makes the early checkpoints cheap to reject — rejecting a reflection
costs one re-run, rejecting an implementation costs the implementation.

## Layout

```text
spec-driven/
└── .claude/
    ├── settings.json               # permissions — denies --no-verify outright
    ├── conventions/
    │   ├── pipeline.md             # THE contract: layout, phases, statuses, staleness
    │   └── challenge.md            # what a legitimate contradiction is
    ├── commands/
    │   ├── spec.md                 # the orchestrator
    │   ├── spec-init.md            # run once, in the host project
    │   ├── spec-new.md             # opens a spec directory
    │   ├── spec-challenge.md       # runs the B side
    │   └── spec-{reflect,analyze,tasks,pseudo,comment,
    │              implement,test,docs,map,recap}.md
    ├── agents/
    │   ├── challenger.md           # model B — disallowedTools: Edit, Write
    │   └── scout.md                # reads many files, returns a small map
    ├── templates/
    │   ├── INDEX.md  JOURNAL.md  challenge.md
    │   └── 01-reflection.md … 10-recap.md
    ├── scripts/
    │   └── checks.sh               # the one quality battery, wired by /spec-init
    └── specs/
        └── <slug>/                 # the artifacts land here
```

## Getting started

```bash
cp -r templates/spec-driven/.claude/* your-project/.claude/
```

Then, in that project:

```text
/spec-init
```

It detects the stack, wires `checks.sh` (CI wins every disagreement), asks you
whether artifacts go in git, and leaves a three-line pointer in `CLAUDE.md` —
not a copy of the rules, because `CLAUDE.md` is re-read every session and every
line is paid for on every turn.

Then, per feature:

```text
/spec rate-limit-login
```

## Two models, not two opinions

A model cannot see its own omissions, and once it has argued for a design that
argument is in its context. So the builder builds, the challenger contradicts,
and **a human arbitrates** — the pipeline has no arbitration step by design.

`/spec-challenge` stops *before* reconciliation, so the builder never receives
findings and resolves them in the same breath.

Three modes, in increasing independence: the `challenger` subagent, a second
session on another model, or an external vendor's model with a manual round trip.
Use the third on phases 01–03, where a wrong framing is the error every later
phase faithfully amplifies.

The failure modes of this arrangement — agreeable convergence, manufactured
findings, shared blind spots, arbitration by the interested party — and the
countermeasure built in for each are in
[`docs/dual-ai-challenge.md`](../../docs/dual-ai-challenge.md).

## What keeps it honest six months later

- **Staleness propagates.** Editing a `resolved` artifact marks every downstream
  `resolved` phase `stale`. The pipeline marks and stops; re-running is a
  decision and it goes in the journal. Without this, a spec directory becomes a
  pile of documents describing three different versions of the same feature.
- **Every phase has an honesty section** — unverified claims, tests not verified,
  unbacked diagram edges, gaps left open. `10-recap.md` aggregates them into one
  confidence statement. That is the answer to "how much should I trust this".
- **Only a human sets `resolved`.** It is the one thing in the pipeline that is
  not automated, and the reason the checkpoints are not decoration.
- **The canonical map outlives the spec.** `docs/architecture/map.md` is updated
  by every spec and owned by none.

## This template vs. `enterprise-monorepo`

Two templates in this repo, two different problems. They are not versions of
each other.

| | `spec-driven` | [`enterprise-monorepo`](../enterprise-monorepo/README.md) |
|--|---------------|--------------------------|
| Organises | **the reasoning** — ten phases, each with an artifact and a contradiction | **the repo** — path-scoped rules, per-directory skills, section boundaries |
| Pipeline | 10 phases, human checkpoint between each | 4 steps: scope → implement → review → report |
| Second opinion | a challenger model, on five mandatory phases | a `code-reviewer` agent, at review time |
| Enforcement | conventions + permissions | 7 hooks + a shared pre-commit battery |
| Use it when | building the wrong thing is expensive | many people work in one large repo |

They compose: nothing stops a monorepo from running `/spec` for its hard changes
and `/ticket` for the rest.

**On the duplication.** `scout` here and `impact-scout` there do a similar job,
and that is deliberate. A template is copied *whole* into one project; it cannot
depend on another template being present. Different names because they are not
the same agent — `scout` also serves phase 09's cartography. If you change one,
the other does not follow, and it should not.

## Adapting it

| Your setup | Change |
|------------|--------|
| Docs live somewhere other than `docs/` | Map path in `commands/spec-map.md` and `templates/09-map.md` — change both |
| Artifacts should not be in git | `/spec-init` asks; gitignore `.claude/specs/` |
| Fewer phases | Drop 04, 05, 09. Keep 01–03 and 10 — they carry most of the value |
| A commit gate like the other template | Wrap `checks.sh` in a `PreToolUse` hook — see [`enterprise-monorepo`](../enterprise-monorepo/.claude/hooks/pre-commit-gate.sh) for the exit-code protocol |
| A different challenger model | `model:` in `agents/challenger.md`, or run it outside the session entirely |

## What this is not

It is not a way to hand over judgement. Every checkpoint exists because a human
decides: is this the right problem, is this the right plan, is this mergeable.
The pipeline removes the variance in *how the work is prepared, contradicted and
reported* — not the decision about whether it is correct.

## See also

- [`docs/dual-ai-challenge.md`](../../docs/dual-ai-challenge.md) — the two-model
  method and its failure modes
- [`docs/ticket-workflow.md`](../../docs/ticket-workflow.md) — the lighter
  four-step pipeline, for ticket-driven work
- [`docs/choosing-a-primitive.md`](../../docs/choosing-a-primitive.md) — why each
  step here is a command, an agent, or a convention
