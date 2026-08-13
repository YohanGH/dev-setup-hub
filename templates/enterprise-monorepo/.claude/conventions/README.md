# Conventions

Long-form, human-owned source of truth for how this repo is written and reviewed.

## How these files reach Claude

`.claude/conventions/` is **not** a folder Claude Code loads by itself. That is
deliberate — these files are the detailed reference, and loading all of them on
every turn would be exactly the always-on context tax we're avoiding.

They reach Claude through three explicit doors:

| Door | File | Loads when |
|------|------|------------|
| Path-scoped rule | `.claude/rules/*.md` | Claude reads a file matching the rule's `paths:` glob. The rule states the non-negotiables inline and points here for detail. |
| Skill | `.claude/skills/project-conventions/SKILL.md` | Claude judges the task is about conventions, or you run `/project-conventions`. |
| Review pipeline | `.claude/skills/review-checklist/SKILL.md` | `/review-scope` runs, which reads `review.md` as its rubric. |

So: **rules carry the 3 lines that must always apply; conventions carry the 300
lines of "why and exactly how"; skills pull them in on demand.**

## Index

| File | Covers |
|------|--------|
| [`git.md`](git.md) | Branches, Conventional Commits, PR shape, merge policy. |
| [`code-style.md`](code-style.md) | Naming, file layout, error handling, comments, dependencies. |
| [`testing.md`](testing.md) | What must be tested, test layout, naming, fixtures, what not to test. |
| [`api-design.md`](api-design.md) | REST contract, status codes, error shape, versioning, pagination. |
| [`security.md`](security.md) | Secrets, input validation, authz, logging, dependency policy. |
| [`review.md`](review.md) | The review rubric — the definition of done used by `/review-scope`. |
| [`documentation.md`](documentation.md) | What gets documented, where, and the ADR format. |

## Maintaining them

- Treat a convention change like any other change: PR, review, merge.
- If a convention is enforced by a linter, formatter or CI, **delete it here** and
  say "enforced by `<tool>`" instead. Duplicated enforcement drifts.
- If a convention keeps being violated by Claude specifically, promote its
  one-line form into the matching `.claude/rules/*.md`, or make it a hook.
- Convert anything that is a *procedure* rather than a *fact* into a skill.
