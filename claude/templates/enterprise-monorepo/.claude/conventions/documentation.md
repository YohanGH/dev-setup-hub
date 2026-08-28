# Documentation conventions

## What gets written, and where

| Change | Documented in |
|--------|---------------|
| A decision with alternatives (framework, storage, protocol, boundary) | An ADR in `docs/adr/` |
| A public API change | The generated OpenAPI spec (from code) + `CHANGELOG.md` |
| A new package or app | Its `README.md` + a row in the root `CLAUDE.md` layout table |
| A new convention Claude must follow | `.claude/conventions/` + a one-line rule in `.claude/rules/` |
| A repeatable procedure | A skill in `.claude/skills/`, not a wiki page |
| A user-visible behaviour change | `CHANGELOG.md` under the next release |

Everything else: the code and its tests are the documentation. A comment that
restates the code is a defect (`code-style.md`).

## ADRs

One decision per file, `docs/adr/NNNN-short-title.md`, never edited after
acceptance — superseded by a new ADR that links back.

```markdown
# NNNN — <decision in one line>

- **Status**: proposed | accepted | superseded by [NNNN](NNNN-....md)
- **Date**: YYYY-MM-DD
- **Deciders**: <names>
- **Ticket**: <TICKET-ID>

## Context
What forces are at play? What constraint made this a decision rather than a
detail? State what we did *not* know.

## Decision
What we are doing, in the active voice: "We will ...".

## Alternatives considered
For each: what it was, and the specific reason it lost. An ADR with no rejected
alternative is a note, not a decision.

## Consequences
What becomes easier. What becomes harder. What we must revisit, and when.
```

## READMEs

Every package README answers, in this order and nothing more:

1. What this is, in one sentence.
2. How to run it locally (exact commands).
3. How to test it.
4. The two or three things that will surprise a newcomer.

No architecture essays in a README — those are ADRs.

## CHANGELOG

Keep a Changelog format, semantic versioning. Entries are written for the
**consumer** of the change, not the author of the commit: "Invoice export now
includes credit notes", not "refactor exporter".

## Style

- Present tense, active voice, second person for instructions.
- Every command shown must be copy-pasteable and actually work.
- Link to the file, don't paraphrase it — paraphrases drift.
- Date anything time-sensitive; relative dates ("recently", "for now") rot.

## For Claude specifically

- Update docs **in the same change** as the code. A follow-up doc commit never
  happens.
- Do not create a new markdown file when an existing one has the right home.
- Do not write a summary document of your own work unless asked — the ticket
  report (`/ticket-report`) is that artifact.
