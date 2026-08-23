---
phase: 04-pseudocode
slug: <SLUG>
status: drafted
author: <builder model / mode>
date: <YYYY-MM-DD>
---

# 04 · Pseudo-code — <SLUG>

> The algorithm, not the implementation. No imports, no framework names, no
> language idioms. If a framework name appears below, this phase stopped doing
> its job.
>
> One block per task from `03-tasks.md` that has non-trivial logic. Trivial
> tasks say "no algorithm" and take one line.

## T<n> — <task title>

### Data

| | Shape | Can be empty / null? | Notes |
|---|-------|----------------------|-------|
| In | | | |
| Out | | | |
| Persisted | | | |

**Invariants.** True before, during and after. These become assertions in 06 and
test names in 07.

- <invariant>

### Steps

```text
given   <input, with its shape>
require <precondition, and what happens when it does not hold>

1. <step>
2. for each <item> in <collection>            # note: collection may be empty
     a. <step>
     b. if <condition> then <step> else <step>
3. <step>

yield   <output, with its shape>
ensure  <postcondition>
```

### Failure modes

Equal space with the happy path, or the phase is not finished. One row per way
this can go wrong — including the ones the code cannot prevent.

| What fails | Caller sees | Left behind | Recoverable |
|------------|-------------|-------------|-------------|
| | error / partial result / silent default | partial write / lock / temp file / nothing | yes / no |

**Silent-wrong.** <The failure that produces a plausible wrong answer instead of
an error. If there is none, say so and why. If there is one, it is the thing
phase 07 must have a test for.>

### Concurrency and ordering

| Assumption | Holds because | Breaks if |
|------------|---------------|-----------|
| e.g. single-threaded, no shared state | | |

### Ideal vs. what the code allows

| | Shape | Cost |
|---|-------|------|
| Ideal | | |
| Taken | | |

**Why the difference.** <The constraint in `02-analysis.md` that forces it, with
its `file:line`. If there is no difference, write "none" — do not invent one.>

### Not specified here

Deliberately left to phase 06. Listed so that 06 deciding them is a choice, not
an accident.

- <naming / file layout / which helper to reuse>

---

## T<n+1> — <task title>

<repeat, or: **No algorithm.** <one line saying why — config change, mechanical
rename, generated file>>

---

## Open questions

| # | Question | Blocks | Who can answer |
|---|----------|--------|----------------|
| Q<n> | | T<n> | |
