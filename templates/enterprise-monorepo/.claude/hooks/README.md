# Hooks

Hooks are the **deterministic** layer. `CLAUDE.md` and rules are context — Claude
reads them and usually complies. A hook is a shell command the harness runs at a
fixed lifecycle event, whatever the model decides. Anything that must happen
every time belongs here, not in a instruction file.

## What is wired, and why

| Event | Script | Job |
|-------|--------|-----|
| `SessionStart` | `session-start-context.sh` | Prints branch, ticket, scope-file state. stdout becomes context — kept short, it is paid every session. |
| `UserPromptSubmit` | `inject-ticket-context.sh` | If the prompt names a ticket with existing artifacts, injects the paths (not the contents). |
| `PreToolUse` · `Bash`, `git commit *` | `pre-commit-gate.sh` | Refuses `--no-verify`; runs preflight and denies a red commit. **The husky role.** |
| `PreToolUse` · `Edit\|Write\|MultiEdit` | `protect-paths.sh` | Denies writes to secrets, build output, vendored code, lockfiles; escalates on `.claude/settings.json`. |
| `PostToolUse` · `Edit\|Write\|MultiEdit` | `format-edited.sh` | Formats what was just written. `async` — never slows a turn. |
| `PostToolUse` · `Bash`, `git commit *` | `post-commit-report.sh` | Appends the commit to `.claude/tickets/<ID>/commits.log`. Makes the report auditable. |
| `Stop` | `quality-gate.sh` | Runs the quick battery before the turn ends. `warn` by default, `block` if you want a hard gate. |

## The husky question

You asked for a pre-commit battery. There are two enforcement points, and you
want **both**, because they cover different actors:

| Actor | Enforced by | Bypass |
|-------|-------------|--------|
| A human running `git commit` | `.githooks/pre-commit` → `preflight.sh` | `--no-verify` (their choice, their responsibility) |
| Claude running `git commit` | `PreToolUse` hook → `preflight.sh` | none — the hook denies `--no-verify` before the command runs |

Both call **the same script**. That is the design: one gate, one definition, no
drift between what CI, a developer, and the agent consider "green".

`pre-commit-gate.sh` detects when `.githooks/` is installed and skips its own run
so the battery doesn't execute twice — it still blocks the bypass flags.

## Output contracts

Get these wrong and the hook silently does nothing.

| Goal | How |
|------|-----|
| Block a tool call | exit `2` with the reason on **stderr**, or exit `0` with `{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."}}` |
| Ask the user instead of blocking | same, with `"permissionDecision":"ask"` |
| Give Claude context | `UserPromptSubmit` → `{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"..."}}`; `SessionStart` → plain stdout |
| Show the user a note | `{"systemMessage":"...","suppressOutput":true}` |
| Prevent the turn from ending | `Stop` → exit `2`, stderr goes to Claude |

Exit `0` with no output = "no opinion, carry on". Any other non-zero exit is a
non-blocking error that only shows in the debug log.

## Rules for writing one

- **Fast or `async`.** A synchronous hook is on the critical path of every turn.
- **Idempotent.** It may run more than once for the same state.
- **Silent on stdout** unless the event treats stdout as context. A stray `echo`
  in a `PreToolUse` hook corrupts the JSON contract.
- **Degrade, don't break.** Missing `jq`, missing formatter, not a git repo →
  exit `0`. A broken hook must never be able to wedge a session.
- **No network, no unpinned remote scripts, nothing outside the repo.**
- **Guard `Stop` against loops.** `stop_hook_active` tells you Stop vs
  SubagentStop; it is *not* a re-entry flag. `quality-gate.sh` uses a
  session+worktree fingerprint marker so one failing state blocks once.

## Testing a hook

Hooks read JSON on stdin. Test them directly — it takes seconds and saves a
confused debugging session:

```bash
# should deny
echo '{"tool_input":{"command":"git commit --no-verify -m x"}}' \
  | .claude/hooks/pre-commit-gate.sh; echo "exit=$?"

# should pass through
echo '{"tool_input":{"file_path":"src/app.ts"}}' \
  | .claude/hooks/protect-paths.sh; echo "exit=$?"

# should deny
echo '{"tool_input":{"file_path":".env"}}' \
  | .claude/hooks/protect-paths.sh; echo "exit=$?"
```

Then `claude --debug` to confirm the harness is actually firing them. Changes to
hooks in `settings.json` need a session restart.

## Turning things off

| Want | Do |
|------|-----|
| No Stop gate | `CLAUDE_QUALITY_GATE=off` |
| Hard Stop gate | `CLAUDE_QUALITY_GATE=block` |
| No commit gate | `CLAUDE_PRECOMMIT_GATE=off` |
| Always run the battery Claude-side | `CLAUDE_PRECOMMIT_GATE=always` |
| Everything off, temporarily | `"disableAllHooks": true` in settings |

Put personal values in `.claude/settings.local.json` (gitignored), not in the
shared file.
