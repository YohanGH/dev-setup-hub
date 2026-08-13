<!-- Language: English · [Français](fr/frontmatter-reference.md) -->

# Frontmatter & file properties reference

Every configurable file type, its fields, and — more usefully — **which fields
are worth setting** for each kind of job.

> Fields come from the official documentation. Claude Code moves fast; when this
> and [the docs](https://code.claude.com/docs/en/skills) disagree, the docs win.

## Skills and commands (`SKILL.md`, `commands/*.md`)

Same mechanism, same frontmatter. `.claude/skills/x/SKILL.md` and
`.claude/commands/x.md` both create `/x`.

| Field | Required | What it does |
|-------|----------|--------------|
| `name` | no | Display name. Defaults to the directory name. |
| `description` | **recommended** | What it does and when to use it. **This is what Claude matches on.** Combined with `when_to_use`, truncated at 1536 chars across the skill list. |
| `when_to_use` | no | Extra trigger phrases. Counts toward the same cap. |
| `argument-hint` | no | Shown during autocomplete, e.g. `[issue-number]`. |
| `arguments` | no | Named positional args → `$name` in the body. Space-separated string or YAML list. |
| `disable-model-invocation` | no | `true` = only you can run it. Also keeps it out of the skill list entirely. |
| `user-invocable` | no | `false` = hidden from the `/` menu, still model-invocable. |
| `allowed-tools` | no | Tools usable **without a permission prompt** while active. Grants, does not restrict. |
| `disallowed-tools` | no | Tools removed from the pool while active. Clears on your next message. |
| `model` | no | Model while active, or `inherit`. Reverts at your next prompt. |
| `effort` | no | `low` · `medium` · `high` · `xhigh` · `max`. |
| `context` | no | `fork` → run in a subagent context. |
| `agent` | no | Which subagent to fork into, with `context: fork`. |
| `paths` | no | Globs restricting auto-activation to matching files. |
| `hooks` | no | Lifecycle hooks scoped to this skill. |
| `shell` | no | `bash` (default) or `powershell` for inline command blocks. |

### Substitutions available in the body

| Token | Expands to |
|-------|-----------|
| `$ARGUMENTS` | everything typed after the name |
| `$ARGUMENTS[N]` / `$N` | the Nth argument, 0-based |
| `$name` | a named argument from `arguments:` |
| `${CLAUDE_SKILL_DIR}` | the skill's own directory — use it to reference bundled files |
| `${CLAUDE_PROJECT_DIR}` | the project root — works in the body **and** in `allowed-tools` |
| `${CLAUDE_SESSION_ID}`, `${CLAUDE_EFFORT}` | session id, current effort level |

### Optimal properties by job

| The skill is… | Set |
|---------------|-----|
| Reference material Claude should find on its own | `description` in the user's words · `when_to_use` |
| A workflow with side effects (commit, deploy, report) | `disable-model-invocation: true` · `argument-hint` |
| Heavy on reading (review, audit, wide search) | `context: fork` · `agent:` · `effort: high` |
| Area-specific | `paths:` — or just place it in that directory's `.claude/skills/` |
| Running a project script | `allowed-tools: Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/x.sh:*)` |
| Background knowledge, never invoked directly | `user-invocable: false` |

Writing a good `description` is the single highest-leverage thing here. Start
with the words a request would contain — "write or change tests in
`packages/api`" beats "testing utilities" — because descriptions get truncated
when many skills exist, and the front of the string is what survives.

## Subagents (`.claude/agents/*.md`)

| Field | Required | What it does |
|-------|----------|--------------|
| `name` | **yes** | Lowercase and dashes. Hooks receive it as `agent_type`. |
| `description` | **yes** | When Claude should delegate here. The routing key. |
| `tools` | no | Tools it may use. Inherits everything if omitted. |
| `disallowedTools` | no | Removed from the inherited or specified list. |
| `model` | no | `sonnet` · `opus` · `haiku` · `fable` · a full id · `inherit` (default). |
| `permissionMode` | no | `default` · `acceptEdits` · `auto` · `dontAsk` · `bypassPermissions` · `plan`. |
| `maxTurns` | no | Hard stop on agent turns. |
| `skills` | no | Skills preloaded **in full** at start — not just their descriptions. |
| `mcpServers` | no | MCP servers available to it. |
| `hooks` | no | Lifecycle hooks scoped to this agent. |
| `memory` | no | `user` · `project` · `local` — persistent learning across sessions. |
| `background` | no | `true` = always run as a background task. |
| `effort` | no | Effort level while active. |
| `isolation` | no | `worktree` = its own git worktree, auto-cleaned if unchanged. |
| `color` | no | `red` `blue` `green` `yellow` `purple` `orange` `pink` `cyan`. |
| `initialPrompt` | no | Auto-submitted first turn when used as a main-thread agent. |

### Optimal properties by role

| The agent is… | Set |
|---------------|-----|
| A read-only explorer | `permissionMode: plan` · `tools: Read, Grep, Glob, Bash` · `model: sonnet` |
| A reviewer | `disallowedTools: Edit, Write` · `skills: <rubric>` · `effort: high` · `permissionMode: plan` |
| A test runner | `disallowedTools: Edit, Write` · `memory: project` · `maxTurns` · `background: true` |
| A long batch job | `background: true` · `effort` matched to the work |
| A risky refactor | `isolation: worktree` |

Two rules that matter more than the table:

1. **Remove the tool rather than asking it not to.** A reviewer with `Edit` will
   eventually fix instead of report. `disallowedTools` is enforcement;
   an instruction is a suggestion.
2. **State the output format in the body.** An agent whose output shape varies
   cannot be a step in a pipeline.

## Path-scoped rules (`.claude/rules/*.md`)

| Field | What it does |
|-------|--------------|
| `paths` | Globs. Loads only when Claude reads a matching file. |
| `description` | Human-facing note; helps whoever maintains the file. |

```markdown
---
description: Backend conventions
paths:
  - "apps/api/**"
  - "src/**/*.{ts,tsx}"
---
```

No `paths:` → loads on every session at `CLAUDE.md` priority. Rules are
discovered recursively, so subdirectories work. Symlinks are followed, which is
how you share one rule set across repos.

## Hook entries (`settings.json`, `hooks/hooks.json`)

```json
{
  "matcher": "Edit|Write",
  "hooks": [{
    "type": "command",
    "if": "Bash(git commit *)",
    "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/x.sh",
    "args": ["--flag"],
    "async": false,
    "timeout": 600,
    "statusMessage": "Checking"
  }]
}
```

| Field | What it does |
|-------|--------------|
| `matcher` | Tool name, `A\|B` list, or regex. Omitted or `*` = all. |
| `type` | `command` · `http` · `mcp_tool` · `prompt` · `agent`. |
| `if` | Extra condition, e.g. `Bash(git commit *)` — narrower than `matcher` alone. |
| `command` | The script. Use `${CLAUDE_PROJECT_DIR}` / `${CLAUDE_PLUGIN_ROOT}`, never a hardcoded path. |
| `args` | Present → direct exec, no shell. Absent → shell command. |
| `async` | `true` = don't block the turn. Use for anything slow and non-blocking. |
| `timeout` | Seconds; 600 default for commands. |
| `statusMessage` | Shown to the user while it runs. |

Full event list and output contracts:
[hooks-and-automation.md](hooks-and-automation.md).

## Settings worth knowing (`.claude/settings.json`)

| Key | Why |
|-----|-----|
| `permissions.allow` / `ask` / `deny` | The enforcement layer. `deny` covers built-in file tools *and* recognised Bash commands like `cat`, `grep`, `find`. |
| `permissions.additionalDirectories` | Access to sibling packages/repos. Does **not** load their `CLAUDE.md` or skills. |
| `claudeMdExcludes` | Ignore other teams' `CLAUDE.md`. Absolute-path globs; start relative patterns with `**/`. Merges across scopes. |
| `worktree.sparsePaths` | Check out only these directories in a worktree. Include `.claude` or the repo config is missing inside it. |
| `worktree.symlinkDirectories` | Symlink `node_modules` instead of duplicating it. |
| `enabledPlugins` | Turn a plugin on for everyone in the repo. |
| `env` | Values your hooks read — the clean way to make a gate configurable. |
| `disableAllHooks` | Escape hatch. |

Project settings load **only from the directory you start Claude in** — they are
not inherited from parent directories the way `CLAUDE.md` files are. A
per-package `.claude/settings.json` must be self-contained.

## Plugins

`.claude-plugin/plugin.json`:

| Field | Notes |
|-------|-------|
| `name` | **Required.** Becomes the skill namespace: `/name:skill`. |
| `description` | Shown in the plugin manager. |
| `version` | Omitted → every git commit is a new version. Set it to control updates. |
| `author`, `homepage`, `repository`, `license`, `keywords` | Optional metadata. |

Directory layout — **only `plugin.json` goes inside `.claude-plugin/`**:

```text
my-plugin/
├── .claude-plugin/plugin.json
├── skills/<name>/SKILL.md
├── agents/<name>.md
├── hooks/hooks.json
├── commands/<name>.md      # legacy flat form; prefer skills/
├── .mcp.json  .lsp.json
├── monitors/monitors.json
├── bin/                    # added to PATH while enabled
└── settings.json           # only `agent` and `subagentStatusLine`
```

Putting `skills/` or `hooks/` inside `.claude-plugin/` is the most common plugin
bug — they are silently ignored.

`.claude-plugin/marketplace.json` at the marketplace root lists plugins with
`name`, `source`, `description`, `version`, `author`, `keywords`, `category`.

## Pre-commit checklist for any config file

- [ ] `description` reads like the request someone would actually make.
- [ ] Side effects → `disable-model-invocation: true`.
- [ ] Heavy reading → `context: fork`, or a subagent.
- [ ] Rules have `paths:`, or they belong in `CLAUDE.md`.
- [ ] `allowed-tools` is the narrowest set that works.
- [ ] Agents that must not write have `disallowedTools`.
- [ ] Hook paths use `${CLAUDE_PROJECT_DIR}` / `${CLAUDE_PLUGIN_ROOT}`.
- [ ] Slow hooks are `async`.
- [ ] `CLAUDE.md` still under ~200 lines.
