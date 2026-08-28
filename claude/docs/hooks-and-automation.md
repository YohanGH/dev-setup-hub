<!-- Language: English · [Français](fr/hooks-and-automation.md) -->

# Hooks & automation

Hooks are the only **deterministic** layer in a Claude Code setup. `CLAUDE.md`,
rules and skills are context: Claude reads them and usually complies. A hook is
a shell command the harness runs at a fixed lifecycle event, whatever the model
decides.

The test: *if Claude ignored this instruction, would that be unacceptable?* If
yes, it is a hook.

## Events

| Phase | Events |
|-------|--------|
| Session | `SessionStart` · `Setup` · `SessionEnd` |
| Turn | `UserPromptSubmit` · `UserPromptExpansion` · `Stop` · `StopFailure` |
| Tools | `PreToolUse` · `PermissionRequest` · `PermissionDenied` · `PostToolUse` · `PostToolUseFailure` · `PostToolBatch` |
| Agents | `SubagentStart` · `SubagentStop` · `TaskCreated` · `TaskCompleted` |
| Context | `InstructionsLoaded` · `PreCompact` · `PostCompact` · `ConfigChange` · `CwdChanged` · `FileChanged` |
| Worktrees | `WorktreeCreate` · `WorktreeRemove` |

The seven that carry almost all real-world value:

| Event | Use it for |
|-------|-----------|
| `SessionStart` | Injecting current state — branch, ticket, environment. stdout becomes context. |
| `UserPromptSubmit` | Adding context conditionally, based on what was asked. |
| `PreToolUse` | **Blocking.** The gate: refuse a command, refuse a write. |
| `PostToolUse` | Reacting: format, log, notify. Usually `async`. |
| `Stop` | Checking work before the turn ends. |
| `SubagentStop` | Same, for a delegated task. |
| `PreCompact` | Persisting state that must survive compaction. |

## Input

Every hook gets JSON on **stdin**:

```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.jsonl",
  "cwd": "/current/working/dir",
  "permission_mode": "default",
  "hook_event_name": "PreToolUse",
  "agent_id": "...", "agent_type": "..."
}
```

Tool events add `tool_name`, `tool_input`, `tool_output`, `tool_error`.
`Stop` adds `last_assistant_message`, `tool_calls`, `tool_results`, and
`stop_hook_active`.

> **`stop_hook_active` is not a re-entry flag.** It is `true` for `Stop` and
> `false` for `SubagentStop`, so one hook can serve both. Guarding against loops
> is your job — see below.

## Output contracts

Get these wrong and the hook silently does nothing.

| Goal | How |
|------|-----|
| No opinion | exit `0`, no output |
| Block a tool call | exit `2` with the reason on **stderr**, or exit `0` with the JSON below |
| Ask the user | same JSON, `"permissionDecision": "ask"` |
| Give Claude context | `UserPromptSubmit` → `additionalContext`; `SessionStart` → plain stdout |
| Note to the user only | `{"systemMessage":"...","suppressOutput":true}` |
| Prevent the turn ending | `Stop` → exit `2`, stderr goes to Claude |

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Destructive command blocked by hook"
  }
}
```

Exit `2` blocks. Any other non-zero exit is a non-blocking error that only
appears in the debug log — which is why a broken hook looks like a hook that
does nothing.

## Writing a hook script

```bash
#!/usr/bin/env bash
set -uo pipefail
INPUT="$(cat)"                                    # read stdin once
CMD="$(printf '%s' "$INPUT" | jq -r '.tool_input.command')"

if printf '%s' "$CMD" | grep -q 'rm -rf /'; then
  jq -n '{hookSpecificOutput:{
      hookEventName:"PreToolUse",
      permissionDecision:"deny",
      permissionDecisionReason:"Refused: destructive command."}}'
fi
exit 0
```

Six rules, each learned the hard way:

1. **Fast, or `async`.** A synchronous hook is on the critical path of every turn.
2. **Idempotent.** It may run twice for the same state.
3. **Silent on stdout** unless the event treats stdout as context. A stray `echo`
   in a `PreToolUse` hook corrupts the JSON contract.
4. **Degrade, never break.** No `jq`, no formatter, not a git repo → exit `0`. A
   hook must never be able to wedge a session.
5. **No network, no unpinned remote scripts, nothing outside the repo.**
6. **Beware `jq`'s `//`.** `false // "default"` yields `"default"`, because `//`
   treats `false` as empty. Reading a boolean field that way inverts your logic.
   Read the path directly and treat only `null`/absent as missing.

### Guarding a `Stop` hook against loops

A `Stop` hook that exits `2` forces the turn to continue. If it does that
unconditionally, the session never ends.

The pattern that works: fingerprint the **content** of the current change
(`git rev-parse HEAD` + `git diff HEAD`), key a marker file on
`session_id + fingerprint`, and block only once per fingerprint. Claude changes
something → new fingerprint → it may block again. Claude changes nothing → same
fingerprint → the turn ends.

Do not fingerprint `git status --porcelain`: its output is identical before and
after editing an already-modified file, so a real fix looks like no change — and
it flips on unrelated untracked noise like a cache directory.

## The husky pattern

Making a pre-commit battery cover **both** humans and Claude:

```text
                       preflight.sh
                    ↑        ↑        ↑
       .githooks/pre-commit  │   your terminal
        (humans commit)      │
                    PreToolUse hook
                    (Claude commits)
```

One script, three entry points. That is the whole trick: CI, a developer and the
agent cannot disagree about what "green" means, because there is only one
definition.

Two things only the Claude-side hook can do:

- **Refuse `--no-verify`.** A human bypassing the gate is making a judgement
  call they own. An agent doing it is routing around a control.
- **Block before the command runs**, with a message written for the model —
  "fix the failures, do not weaken a check" — instead of a raw non-zero exit.

The Claude-side hook should detect that `core.hooksPath` is installed and skip
its own run, so the battery does not execute twice.

Worked implementation:
[`templates/enterprise-monorepo/.claude/`](../templates/enterprise-monorepo/.claude/)
— `hooks/pre-commit-gate.sh`, `scripts/preflight.sh`,
`scripts/install-git-hooks.sh`.

## Scripts worth having

| Script | Event | Job |
|--------|-------|-----|
| `preflight.sh` | `PreToolUse` + git + CLI | Stack-detecting format/lint/typecheck/test battery. `--changed` vs `--all`. |
| `scan-secrets.sh` | inside preflight | High-signal patterns over changed files only. |
| `protect-paths.sh` | `PreToolUse` | Deny writes to secrets, build output, generated code, lockfiles. |
| `format-edited.sh` | `PostToolUse`, `async` | Format what was just written, if a formatter exists locally. |
| `session-start-context.sh` | `SessionStart` | Branch, ticket, scope-file state. Short — it is paid every session. |
| `inject-ticket-context.sh` | `UserPromptSubmit` | Point at existing ticket artifacts when the prompt names one. |
| `post-commit-report.sh` | `PostToolUse`, `async` | Append the commit to the ticket log — evidence the model didn't write. |
| `quality-gate.sh` | `Stop` | Quick battery before the turn ends. `warn` / `block` / `off`. |

Keep the shared helpers in `lib/common.sh` and source it. A secret-scan pattern
list or a package-manager detector duplicated across eight scripts will drift.

**Make the aggressive ones configurable.** A gate that cannot be turned off for
an afternoon of spike work gets disabled permanently.

## Testing

Hooks read JSON on stdin, so test them directly:

```bash
echo '{"tool_input":{"command":"git commit --no-verify -m x"}}' \
  | .claude/hooks/pre-commit-gate.sh; echo "exit=$?"

echo '{"tool_input":{"file_path":".env"}}' \
  | .claude/hooks/protect-paths.sh | jq .
```

Then `claude --debug` to confirm the harness fires them. Changes to hooks in
`settings.json` need a session restart; plugin hooks need `/reload-plugins`.

## Security

Hooks execute arbitrary shell with your credentials, and they run automatically.

- Review every hook in a repo before trusting the workspace.
- Never `curl | sh`, never call an unpinned remote script.
- Quote every variable — a file path with a space is not an edge case.
- Prefer `permissions.deny` for what must never happen at all: it is enforced by
  the client and covers recognised Bash commands too.
