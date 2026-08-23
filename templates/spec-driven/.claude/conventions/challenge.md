# The challenge contract

Every phase artifact is written by one model and attacked by another. This file
defines what a legitimate attack is, so that "two AIs" produces signal instead
of two opinions and a coin flip.

## Who is the challenger

Three ways to run the B side, in increasing order of independence:

| Mode | How | Independence |
|------|-----|--------------|
| **Subagent** | `@challenger` — separate context window, reads only the artifact and the repo | Fresh context, same model family. Catches unstated assumptions and missing evidence; shares the model's blind spots. |
| **Second session** | A second Claude session with `--model` set to a different model | Different weights, different failure modes. |
| **External model** | Paste the artifact into another vendor's model, paste the challenge back as `NN-<phase>.challenge.md` | Highest. No shared training bias, no shared context. Costs a manual round trip. |

The pipeline does not care which one produced the file. It cares that the file
exists, follows this contract, and names its author in the frontmatter.

Do not let the builder challenge its own artifact in the same context. It will
defend it. That is not a claim about honesty — a model that just argued for a
design has that argument in its context, and it weighs it.

## What a finding must contain

A finding without all three is a nit and belongs in the nit list:

1. **The claim** — what is wrong, in one sentence.
2. **The evidence** — `file:line`, a quoted line from the artifact, or a command
   whose output contradicts it.
3. **The consequence** — what goes wrong downstream if it ships as written. Not
   "this is unclear", but "phase 04 will design for a single tenant and 06 will
   have to be rewritten".

## Severity

| Severity | Test |
|----------|------|
| `blocker` | The next phase would build the wrong thing |
| `major` | The next phase would build the right thing the wrong way |
| `minor` | Correct but will cost someone time later |
| `nit` | Preference. Listed, never acted on without a human's say-so |

## The four passes

Run them in order. Stop early only if a `blocker` invalidates the premise.

1. **Premise.** Is the problem stated the problem that exists? An artifact that
   solves the wrong problem correctly is the most expensive failure in this
   pipeline, and it is only catchable here.
2. **Evidence.** Every factual claim: verified, unverifiable, or false. A path
   that does not exist, a function that has no such signature, a test that is
   not there. Open the file — do not pattern-match the plausibility of the name.
3. **Omission.** What is not in the artifact that should be: the error path, the
   migration, the caller nobody listed, the sibling implementation, the case
   where the input is empty. Omissions are what a self-review misses; this pass
   is the challenger's main value.
4. **Falsifiability.** Could this artifact be wrong and still look like this? If
   nothing in it could be checked against reality, say so — that is a `major`.

## What the challenger must not do

- **Fix anything.** `disallowedTools: Edit, Write, NotebookEdit`. A challenger
  that edits stops being able to see.
- **Rewrite the artifact in its own voice.** "Here is how I would have written
  it" is not a finding.
- **Manufacture findings.** Reporting `accept` with an empty findings list is a
  complete, successful challenge. A challenger rewarded for volume produces
  volume.
- **Restate the artifact.** Summary is not review.
- **Repeat one defect ten times.** Report the pattern once, list the locations.

## Reconciliation

The builder owns reconciliation, and it happens in the open:

1. For each `blocker` and `major`: amend the artifact, **or** write why it should
   not be amended. Silence is not a response.
2. Every amendment gets a `JOURNAL.md` entry naming the finding it answers.
3. `minor` and `nit` are listed in the journal as untouched, so the next reader
   knows they were seen and passed over.
4. The human reads the artifact, the challenge, and the journal delta, then sets
   the phase to `resolved`.

If the builder and the challenger disagree after one round, **the disagreement
itself goes to the human** — verbatim, both positions, no arbitration. Two models
converging by concession is worse than an escalation: it looks like consensus.

## Cost

A challenge doubles the token cost of a phase. That is the point, and it only
pays where a wrong answer is expensive.

**Mandatory on 01, 02, 03, 06, 07.** Two different reasons:

- **01–03 (direction).** A wrong premise, a missed caller, a task list that omits
  the migration — caught here it costs a re-run of one cheap phase; caught at 06
  it costs the implementation.
- **06–07 (consequence).** This is where a wrong answer stops being a document
  and becomes shipped code, or a test suite that is green for the wrong reason.

**Optional on 04, 05, 08, 09, 10.** Their errors are visible in the diff or
cheap to fix later. Skipping is legitimate — skipping *silently* is not:
`INDEX.md` records `challenge: skipped (<reason>)`, never a blank cell.

Phase 10 is the one to skip by default. A recap built only from artifacts and
pasted command output has little left to contradict; challenge it when the recap
is going somewhere you cannot correct afterwards.
