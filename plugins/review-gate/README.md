# review-gate

A portable quality gate for Claude Code. Install it once, get the same
enforcement in every repo — no per-project scripts to copy or keep in sync.

## What it does

| Event | Behaviour |
|-------|-----------|
| Claude runs `git commit` | Refuses `--no-verify` / `-n`. Runs the project's checks and **denies the commit** if they fail. |
| Claude edits a file | Refuses writes to `.env*`, keys, `secrets/`, build output, generated code, vendored code, and lockfiles. |
| Claude finishes a turn | Runs the quick battery. Warns by default; set `CLAUDE_REVIEW_GATE=block` to prevent the turn ending on a red tree. |
| You run `/review-gate:gate-status` | Reports what passes and what fails, honestly. |
| You use `@diff-reviewer` | Reviews the branch by severity, reports, never fixes. |

## Install

From this repo, as a local marketplace:

```shell
/plugin marketplace add ./plugins
/plugin install review-gate@claude-config
```

Try it without installing:

```bash
claude --plugin-dir ./plugins/review-gate
```

Enable it for everyone in a repo — commit this to `.claude/settings.json`:

```json
{ "enabledPlugins": ["review-gate@claude-config"] }
```

After changing plugin files, run `/reload-plugins`.

## How it decides what "green" means

1. **If the repo has `.claude/scripts/preflight.sh`, that wins.** The team's own
   definition beats the plugin's guess, and nothing runs twice.
2. Otherwise it detects the stack and runs what it finds: npm/yarn/pnpm/bun
   `lint`, `typecheck`, `test` scripts · `ruff` + `pytest` · `go vet` +
   `go test` · `cargo clippy` + `cargo test`.
3. If it finds nothing to run, it stays out of the way — it never blocks on its
   own inability to check.

It also stands down when the repo installs its own git `pre-commit` hook
(`core.hooksPath=.githooks`), since git already runs the battery.

## Configuration

| Variable | Values | Effect |
|----------|--------|--------|
| `CLAUDE_REVIEW_GATE` | `warn` (default) · `block` · `off` | How the `Stop` hook reacts to failing checks. |

Set it in `.claude/settings.local.json` under `env` for a personal choice, or in
`.claude/settings.json` to make it the team's.

## Structure

```text
review-gate/
├── .claude-plugin/plugin.json   # manifest — only this file lives in .claude-plugin/
├── hooks/hooks.json             # the three hooks
├── scripts/guard.sh             # one script, three modes: commit | write | stop
├── skills/gate-status/SKILL.md  # /review-gate:gate-status
└── agents/diff-reviewer.md      # @diff-reviewer
```

Everything except the manifest sits at the **plugin root** — a common mistake is
nesting `skills/` or `hooks/` inside `.claude-plugin/`, where they are ignored.

Paths inside `hooks.json` use `${CLAUDE_PLUGIN_ROOT}`, which resolves wherever
the plugin is installed. Never hardcode a path in a plugin.

## Plugin or in-repo config?

Both work; they differ in who owns the update.

| | In-repo (`.claude/`) | Plugin |
|---|---|---|
| Lives with the code it governs | yes | no |
| Same rules across many repos | copy-paste, drifts | one source, versioned |
| Update all repos at once | no | yes, bump the version |
| Skill names | `/gate-status` | `/review-gate:gate-status` |
| Can reference repo-specific conventions | yes | only by deferring, as above |

Rule of thumb: **repo-specific instructions stay in the repo; enforcement that
should be identical everywhere becomes a plugin.** The
[enterprise-monorepo template](../../templates/enterprise-monorepo/) ships the
in-repo form of the same gate — adopt one, not both. If you install this plugin
in a repo that already has `.claude/scripts/preflight.sh`, the plugin defers to
it, so having both is harmless but redundant.

## Testing it

```bash
echo '{"tool_input":{"command":"git commit --no-verify -m x"}}' \
  | ./scripts/guard.sh commit | jq -r '.hookSpecificOutput.permissionDecision'
# -> deny

echo '{"tool_input":{"file_path":".env"}}' \
  | ./scripts/guard.sh write | jq -r '.hookSpecificOutput.permissionDecision'
# -> deny

claude plugin validate ./plugins/review-gate
```
