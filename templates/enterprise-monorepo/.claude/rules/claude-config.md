---
description: How to change the Claude Code configuration itself — loaded when touching .claude/
paths:
  - ".claude/**"
  - "**/CLAUDE.md"
---

# Changing the Claude Code configuration

This directory is code that shapes every session. Changing it is a reviewed
change like any other.

## Put each thing in its right place

| The behaviour is… | It belongs in |
|-------------------|---------------|
| Always true, one line, needed every turn | root or per-directory `CLAUDE.md` |
| True only for some paths | `.claude/rules/<topic>.md` with `paths:` |
| Long-form reference a human maintains | `.claude/conventions/<topic>.md` |
| A repeatable procedure Claude may pick up on its own | `.claude/skills/<name>/SKILL.md` |
| A procedure only a human should trigger | same, plus `disable-model-invocation: true` |
| A large or noisy sub-task worth isolating | `.claude/agents/<name>.md` |
| Must happen deterministically, whatever the model decides | a hook in `.claude/settings.json` |
| Shared across repos, versioned | a plugin |

## Rules

- **`CLAUDE.md` stays under ~200 lines.** If it grows, move the new content to a
  path-scoped rule or a skill — never let it accumulate.
- Every rule file must have a `paths:` glob. A rule without one loads on every
  session and is really a `CLAUDE.md` entry in disguise.
- Skill `description:` starts with the words a request would actually contain —
  it is what Claude matches on, and it gets truncated when many skills exist.
- Never widen `permissions.allow` to silence a prompt you found annoying. Add the
  narrowest rule that covers the real command, or leave it in `ask`.
- Never add a hook that writes outside the repo, calls the network, or runs an
  unpinned remote script.
- Hooks must be fast and idempotent. Anything over a few seconds runs `async`.
- Test a hook before committing it:
  `echo '<json>' | .claude/hooks/<hook>.sh; echo "exit=$?"`.
- After changing a plugin, run `/reload-plugins`; after changing settings hooks,
  restart the session.
