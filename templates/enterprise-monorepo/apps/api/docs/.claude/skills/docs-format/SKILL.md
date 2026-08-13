---
name: docs-format
description: Write or edit documentation under apps/api/docs — API guides, ADRs, runbooks. Use when adding or changing a markdown document in this package.
allowed-tools: Read Grep Glob Edit Write Bash
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-markdown.sh"
          async: true
          timeout: 60
---

# Documentation format

Loads only while working in `apps/api/docs/`.

> **This skill carries its own hook.** The `hooks:` block above runs a markdown
> linter after every edit — but **only while this skill is active**. That is the
> mechanism for scoping enforcement to a section without giving every session in
> the repo a markdown linter it will never use. See
> [`docs/context-economics.md`](../../../../../../../../docs/context-economics.md).

## Structure of every document

Answer, in this order, and stop:

1. **What this is**, one sentence.
2. **Who it is for** and when they would read it.
3. The content.
4. What this document deliberately does *not* cover, and where that lives.

A document with no audience stated is a document nobody maintains.

## Style

- Present tense, active voice, second person for instructions.
- Every command shown must be copy-pasteable and must actually work. Verify it
  before writing it — a stale command is worse than no command.
- Link to files, don't paraphrase them — write a real markdown link to
  `../src/core/errors.ts` rather than describing what it does. Paraphrases drift
  silently.
- Tables for anything with more than two parallel facts. Prose for reasoning.
- Date anything time-sensitive. "Recently", "for now" and "currently" rot.
- No screenshots of text. They cannot be searched, diffed, or updated.

## Types of document here

| Type | Goes in | Rule |
|------|---------|------|
| API guide | `docs/api/` | Generated from OpenAPI where possible — never hand-maintained twice |
| ADR | `docs/adr/NNNN-title.md` | One decision, never edited after acceptance; superseded by a new one |
| Runbook | `docs/runbooks/` | Written for someone paged at 3am: symptom → check → action |
| Everything else | reconsider | The code and its tests are documentation |

## Runbooks specifically

Written for a tired stranger. Symptom first, not architecture. Every step is a
command with its expected output. State explicitly what to do when a step
fails — a runbook that only describes the happy path is the one that gets
abandoned during the incident it was written for.
