---
name: project-conventions
description: Look up this repo's written conventions for git, code style, testing, API design, security, review, or documentation. Use when unsure how something is done here, before proposing a pattern, or when asked what the convention is.
when_to_use: Triggered by "what's our convention for", "how do we usually", "is this the right pattern here", or any disagreement about house style.
user-invocable: true
allowed-tools: Read Grep Glob
---

# Project conventions

The conventions live in [`.claude/conventions/`](../../conventions/). They are
**not** loaded automatically — this skill is the router. Read only the file that
answers the question; reading all seven defeats the purpose.

| Question | File |
|----------|------|
| Branch names, commit format, PR shape, merge policy | `conventions/git.md` |
| Naming, file layout, error handling, comments, dependencies | `conventions/code-style.md` |
| What to test, test layout, doubles, what not to test | `conventions/testing.md` |
| Endpoints, status codes, error shape, versioning, pagination | `conventions/api-design.md` |
| Secrets, validation, authz, logging, supply chain | `conventions/security.md` |
| Severity scale, review passes, output format | `conventions/review.md` |
| ADRs, READMEs, changelog, what gets documented | `conventions/documentation.md` |

Path-scoped rules in [`.claude/rules/`](../../rules/) carry the same rules in
one-line form and load automatically for matching files. If a rule and a
convention disagree, **the convention file is the source of truth** and the rule
is stale — say so.

## Answering a convention question

1. Read the one relevant file.
2. Quote the rule and link it as `.claude/conventions/<file>.md`.
3. If the repo's code contradicts the written convention, say which is which.
   Existing code is precedent, not permission — but a convention nobody follows
   is a convention that needs deleting, and that's worth reporting.
4. If the question isn't covered, say so plainly. Do not invent a house rule and
   present it as one — propose it as a proposal.

## Adding or changing a convention

A convention is worth writing down only if it is: stable, non-obvious, not
already enforced by a tool, and violated often enough to matter.

- Long-form reasoning → `.claude/conventions/<topic>.md`.
- Its one-line enforceable form → the matching `.claude/rules/*.md`.
- If a tool could enforce it instead, configure the tool and delete the prose.

See `.claude/rules/claude-config.md` for where each kind of instruction belongs.
