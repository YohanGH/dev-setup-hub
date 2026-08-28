---
description: Run the local quality battery (format, lint, typecheck, tests) the way CI will
argument-hint: "[--all | --changed | --quick]"
arguments: scope
disable-model-invocation: true
allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/preflight.sh:*) Read Grep
---

Run the quality battery:

```bash
.claude/scripts/preflight.sh $scope
```

`--changed` (default) runs against files changed versus the merge base.
`--all` runs the full battery, exactly as CI does. `--quick` skips tests.

Then report:

| Check | Result | Detail |
|-------|--------|--------|
| format | pass/fail | |
| lint | pass/fail | first 3 findings |
| typecheck | pass/fail | first 3 errors |
| tests | pass/fail | n passed / n failed / n skipped |

Rules for what you do next:

- **Report the real result.** Never summarise a failure as "mostly passing".
- If something fails, show the actual error output before proposing anything.
- Fix only what you broke in this session. A pre-existing failure gets reported
  as pre-existing — confirm with `git stash` + re-run if you are unsure, and say
  that you checked.
- Never make a check pass by weakening it: no `skip`, no loosened assertion, no
  disabled rule, no `--no-verify`. If a check blocks legitimately, stop and tell
  me.
