---
name: gate-status
description: Run the project's quality checks and report what passes and what fails. Use when asked whether the tree is green, before committing, or after the gate blocked something.
argument-hint: [--all]
disable-model-invocation: true
allowed-tools: Bash Read Grep
---

# Gate status

Run the battery and report it honestly.

```bash
${CLAUDE_PLUGIN_ROOT}/scripts/guard.sh stop < /dev/null
```

For the detailed run, prefer the project's own gate when it exists — it is the
definition the team agreed on:

```bash
.claude/scripts/preflight.sh --all   # if present
```

Report:

| Check | Result | Detail |
|-------|--------|--------|
| lint | pass/fail | first 3 findings |
| typecheck | pass/fail | first 3 errors |
| tests | pass/fail | n passed / n failed / n skipped |

Rules:

- Paste the real output. Never summarise a failure as "mostly passing".
- Distinguish **your** failures from pre-existing ones — verify with `git stash`,
  re-run, `git stash pop`, and say that you checked.
- Never make a check pass by weakening it: no `skip`, no loosened assertion, no
  disabled rule, no `--no-verify`. If a check blocks legitimately, say so and
  stop.
