<!-- Language: English · [Français](fr/dual-ai-challenge.md) -->

# Two models, one artifact

A model cannot see its own omissions. It can re-read what it wrote all day and
keep finding the things it already thought of — that is what having written it
means. And once it has argued for a design, that argument is in its context, and
it weighs.

So the [spec-driven pipeline](../templates/spec-driven/README.md) splits the work
in two: one model **builds** the artifact, another **attacks** it, and a human
decides. Not "ask twice and see if they agree".

## What this is not

**Not a vote.** Two models agreeing tells you they share a prior, not that the
answer is right. Agreement between models trained on overlapping data is the
cheapest thing in this setup to obtain and the least informative to receive.

**Not a negotiation.** If the builder and the challenger converge by mutual
concession, you get a middle position neither of them would defend, wearing the
appearance of consensus. That is strictly worse than an open disagreement, which
at least tells you where to look.

**Not a second opinion.** A second opinion is what you ask when you want
reassurance. The challenger is asked for findings — specific, evidenced,
consequential — and "no findings" is a complete answer it is allowed to give.

## The asymmetry

| Role | Does | Never does |
|------|------|------------|
| **Builder** (A) | Writes the artifact. Reconciles findings in the open, amending the artifact or stating why not. | Challenges its own artifact in the same context. |
| **Challenger** (B) | Four passes: premise, evidence, omission, falsifiability. Findings with a downstream consequence, and one verdict. | Edits anything. Rewrites the artifact in its own voice. Arbitrates. |
| **Human** | Reads the artifact, the challenge and the journal delta. Sets the phase `resolved`. | Delegates that decision. |

The roles are enforced, not requested: the `challenger` subagent ships with
`disallowedTools: Edit, Write, NotebookEdit`. A reviewer that can fix will fix,
and then it can no longer see the code.

## Three ways to run the B side

| Mode | How | Independence | Cost |
|------|-----|--------------|------|
| **Subagent** | `/spec-challenge <slug> <phase>` — forks a fresh context in the same session | Fresh context, same model. Catches unstated assumptions and unverified claims; shares the model's blind spots. | Tokens only |
| **Second session** | A second Claude session on a different model | Different weights, different failure modes | Tokens + a window |
| **External model** | Paste the artifact into another vendor's model, paste the result back | Highest — no shared training bias, no shared context | A manual round trip |

Independence is the only axis that matters here, and it is bought with
inconvenience. Use the subagent by default; use an external model on the phases
where a wrong answer is expensive — **01 reflection, 02 analysis, 03 tasks**.
Those are the phases whose errors every later phase faithfully amplifies.

## Running an external model

The challenge file does not care what produced it. It cares that the contract in
[`conventions/challenge.md`](../templates/spec-driven/.claude/conventions/challenge.md)
is followed and that the author is named.

Give the other model the artifact and this:

```text
You are reviewing a design artifact written by another model. Do not rewrite it
and do not summarise it. Find what is wrong with it.

Four passes, in order:
1. Premise — is the problem it states the problem that exists?
2. Evidence — every factual claim: verified, unverifiable, or false.
3. Omission — what should be here and is not: the error path, the caller nobody
   listed, the migration, the empty input, the case that already exists.
4. Falsifiability — could this be wrong and still look like this?

Every finding needs three things or it is a nit: the claim in one sentence, the
evidence (a quoted line, a file:line, or a command whose output contradicts it),
and the concrete consequence in the NEXT phase of the work.

Severity: blocker (the next phase builds the wrong thing) · major (the right
thing the wrong way) · minor (correct, costs someone time later) · nit.

Reporting zero findings is a complete and successful review. Do not manufacture
findings to look thorough. End with exactly one verdict: accept, revise, or
reject.
```

Paste its output into `NN-<phase>.challenge.md`, set the `Challenger.` line to
the vendor and model, and update `INDEX.md` by hand.

The external model does not get the repo, so its evidence pass is weaker and its
omission pass is stronger — it has nothing to anchor on but the artifact itself.
That trade is usually the right way round for phases 01 to 03, where the artifact
*is* the thing being judged.

## The four failure modes

These are the ways a two-model setup produces confidence without producing
information. Each one has a countermeasure built into the pipeline.

### 1. Agreeable convergence

The challenger agrees because agreement is the path of least resistance,
especially when the artifact is fluent and confident.

**Countermeasure.** The challenger receives the artifact and the repo — never the
builder's reasoning for writing it. It is asked for findings, not for an
assessment. And it is told, explicitly, that zero findings is a valid answer, so
"I found nothing" does not have to be dressed up as "this looks broadly
reasonable, though you might consider…".

### 2. Manufactured findings

A challenger that senses it is being paid by the finding will produce findings.
Volume looks like rigour and costs nothing to generate.

**Countermeasure.** Every finding must name a concrete consequence in the *next*
phase. "This is unclear" does not survive that filter; "phase 04 will design for
a single tenant and 06 will have to be rewritten" does. Everything that fails the
filter goes to the nit list, which nobody is required to act on.

### 3. Shared blind spots

Two models from the same family miss the same things. A fresh context does not
fix a systematic bias — it just gives you two runs of it.

**Countermeasure.** Mode selection. The subagent is enough to catch unverified
claims and unstated assumptions, because those are context artifacts. It is not
enough to catch a wrong framing that both models find natural. That is what the
external model is for, and it is why it is recommended precisely on the framing
phases.

### 4. Arbitration by the interested party

The builder receives the findings and reconciles them — in the same breath. It
will resolve the uncomfortable ones in its own favour, fluently.

**Countermeasure.** `/spec-challenge` **stops** after writing the challenge file.
Reconciliation is a separate step, after a human has read the contradiction.
Every amendment is journaled with the finding id it answers, and findings left
unaddressed are listed as unaddressed. If the two still disagree after one round,
both positions go to the human verbatim — the pipeline has no arbitration step,
by design.

## Where it pays

Mandatory on **01, 02, 03** (direction) and **06, 07** (consequence). Optional on
04, 05, 08, 09, 10.

The reasoning is the cost of being wrong, not the difficulty of the phase. A
wrong premise caught at 01 costs one cheap re-run; caught at 06 it costs the
implementation. A test suite that is green for the wrong reason is the most
expensive artifact in the pipeline, because everything downstream trusts it.

Phase 10 is the one to skip by default: a recap built only from artifacts and
pasted command output has little left to contradict.

## What it leaves behind

The challenge files are never rewritten. Six months later, `03-tasks.md` tells
you what was planned and `03-tasks.challenge.md` tells you what had to be argued
to get there — including the objection that was raised, considered, and
overruled.

That second document is the one you want when the thing breaks. "We knew, and
here is why we shipped anyway" is a different situation from "nobody thought of
it", and only one of them is a process failure.

## See also

- [`templates/spec-driven/`](../templates/spec-driven/README.md) — the pipeline
  this doc describes
- [`conventions/challenge.md`](../templates/spec-driven/.claude/conventions/challenge.md)
  — the contract the challenge files follow
- [agents-and-autonomy.md](agents-and-autonomy.md) — subagents, forked context,
  and what makes an agent safe to leave alone
- [context-economics.md](context-economics.md) — what a forked challenge actually
  costs per phase
