---
phase: 01-reflection
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
---

# 01 · Reflection — <SLUG>

> Phase 01 writes no code and proposes no design. It establishes that the
> problem is real, is not already solved, and states what would prove this the
> wrong thing to build.

## The problem

<One paragraph. The problem, not the symptom, not the feature request.>

**Evidence.** Quote it — you do not get to assert this.

| What was observed | Where | Source |
|-------------------|-------|--------|
| <failing case, log line, user behaviour, ticket sentence> | `file:line` / ticket / incident | |

**Symptom vs. problem.** <What someone reported, and what is actually underneath
it. If they are the same thing, say so — sometimes they are.>

## Does this already exist?

The most valuable output of this phase when the answer is yes.

| Checked | How | Result |
|---------|-----|--------|
| Existing implementation | `Grep <domain noun>` | |
| Sibling pattern elsewhere | | |
| Previous attempt | `git log -S"<symbol>"` | |
| Abandoned / dead code | | |

## Constraints that decide the design

Only the ones that **eliminate an option**. A list of everything true about the
system belongs in phase 02.

| Constraint | Hard or soft | Eliminates |
|------------|--------------|------------|
| | | |

## Options

At least three, including *do nothing* and *the smallest thing that removes the
symptom*. If one option is obviously right, this table was written backwards from
the conclusion — redo it.

### Option A — <name>

**What it is.** <two lines>
**Cost.** <effort, risk, what it locks in>
**Gives up.** <the thing you no longer get>

### Option B — <name>

**What it is.**
**Cost.**
**Gives up.**

### Option C — do nothing

**What it is.** Leave it. <What happens then, concretely.>
**Cost.** <The recurring cost of the status quo — this is what the other options
have to beat.>
**Gives up.**

## Chosen direction

**<Option X>**, because <the constraint or evidence that forced it — not the
preference>.

**What this commits us to.** <The door this closes. Say it now, while it is
cheap.>

## What would make this the wrong thing to build

Checkable conditions — a number, a behaviour, a fact someone could verify today.
"If users turn out to want X" is not checkable.

| If this is true | Then | How to check |
|-----------------|------|--------------|
| | the chosen direction is wrong | |
| | the problem is not worth solving | |

## Non-goals

Recorded so phase 02 does not analyse them and review does not read them as
oversights.

| Not doing | Why | Revisit when |
|-----------|-----|--------------|
| | | |

## Open questions

Questions that change what gets built. Each one blocks this phase until a human
answers it. An assumption is not an answer — if you assumed, move the row to
Decisions and write the rationale.

| # | Question | Why it changes the build | Who can answer |
|---|----------|--------------------------|----------------|
| Q1 | | | |

## Decisions taken in this phase

Copied to `INDEX.md` → Decisions in force, and journaled.

| Decision | Rationale | Alternative dropped |
|----------|-----------|---------------------|
| | | |
