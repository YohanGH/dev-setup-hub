<!-- Language: English · [Français](fr/configuration.md) -->

# Configuring Claude Code

Everything you can hand to Claude Code to shape how it behaves — for a single
project or globally across all of them.

> Source of truth: <https://code.claude.com/docs/en/settings>.

---

## The big picture

Claude Code reads configuration from several places and **layers them**. There
are two things to configure:

1. **Settings** (`settings.json`) — behavior, permissions, hooks, model, env.
2. **Memory** (`CLAUDE.md`) — persistent instructions and project context.

Plus **MCP servers** (extra tools) and **commands / subagents / hooks** covered
in [commands.md](commands.md).

---

## 1. Settings files (`settings.json`)

### Where they live

| Scope | Path | Commit to git? |
|-------|------|----------------|
| **User / global** | `~/.claude/settings.json` | n/a (personal machine) |
| **Project (shared)** | `.claude/settings.json` | ✅ yes — shared with the team |
| **Project (local)** | `.claude/settings.local.json` | ❌ no — gitignore it |
| **Enterprise (managed)** | OS-specific managed path | Set by administrators |

### Precedence (highest wins)

```
Enterprise managed  >  Command-line args  >  .claude/settings.local.json
                    >  .claude/settings.json  >  ~/.claude/settings.json
```

So a project's local settings override the project's shared settings, which
override your global settings.

### Common fields

```jsonc
{
  // Which model to use by default
  "model": "claude-sonnet-5",

  // Environment variables injected into the session
  "env": {
    "MY_PROJECT_ENV": "staging"
  },

  // Permissions: what Claude may run without asking
  "permissions": {
    "allow": [
      "Bash(npm run test:*)",
      "Bash(git status)",
      "Read(./src/**)"
    ],
    "ask": [
      "Bash(git push:*)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./secrets/**)"
    ],
    "defaultMode": "acceptEdits",
    "additionalDirectories": ["../shared-lib"]
  },

  // Add Co-Authored-By trailer to commits Claude makes
  "includeCoAuthoredBy": true,

  // Days before old chat transcripts are cleaned up
  "cleanupPeriodDays": 30
}
```

> Use `.jsonc`-style comments only as documentation here — the real
> `settings.json` must be valid JSON (no comments).

### Editing tips

- Run `/config` to open the settings UI instead of hand-editing.
- Run `/permissions` to adjust the allow / ask / deny lists interactively.
- Keep **secrets out** of `settings.json`; use `env` for references, not values.

---

## 2. Memory (`CLAUDE.md`)

`CLAUDE.md` files are instructions Claude reads automatically at the start of a
session. Use them for conventions, architecture notes, and "always do X".

| Scope | Path | Purpose |
|-------|------|---------|
| **User / global** | `~/.claude/CLAUDE.md` | Preferences that apply to every project. |
| **Project (shared)** | `./CLAUDE.md` | Team conventions, committed to git. |
| **Project (local)** | `./CLAUDE.local.md` | Personal, uncommitted notes (gitignore it). |

### Generating one

Run `/init` in a project to have Claude analyze the codebase and draft a
`CLAUDE.md`. Then trim it to what actually matters.

### Imports

A `CLAUDE.md` can pull in other files so you don't repeat yourself:

```markdown
See @docs/architecture.md for the module layout.
Follow the coding rules in @~/.claude/my-standards.md.
```

### What makes a good `CLAUDE.md`

- **Short and specific** — bullet rules beat long prose.
- Commands to run (test, lint, build) and how to run them.
- Conventions that are not obvious from the code.
- Things Claude keeps getting wrong — encode the correction.

Edit anytime with `/memory`.

### How big can a `CLAUDE.md` be?

There is **no hard character limit**: a `CLAUDE.md` is loaded **in full**, however
long it is. But length has a real cost — it's injected into the context window at
the start of *every* session, spending tokens and, past a point, *reducing*
adherence (Claude has more to sift through).

- **Target: under ~200 lines** per file. This is the official guideline, not a
  hard cap — the file still loads if it's longer.
- If it's growing, don't just keep appending. Instead:
  - Move file-type-specific instructions to [`.claude/rules/`](https://code.claude.com/docs/en/memory#organize-rules-with-.claude%2Frules%2F)
    with a `paths:` frontmatter, so they load only when Claude touches matching files.
  - Move repeatable, task-specific procedures to a [Skill or command](commands.md)
    (loaded on demand, not every session).
  - Use `@path` imports for organization — but note imported files **still load at
    launch**, so they don't reduce context, only tidy the file.

> The **200-line / 25 KB** limit you may have seen applies to **auto-memory**
> (`MEMORY.md`, which Claude writes itself) — only its first 200 lines or 25 KB
> are loaded. That cap does **not** apply to `CLAUDE.md`, which always loads whole.

---

## 3. MCP servers (extra tools)

[MCP](https://docs.claude.com/en/docs/claude-code/mcp) lets Claude Code talk to
external tools (databases, browsers, issue trackers, …).

| Scope | Where | Shared? |
|-------|-------|---------|
| **Local** | your machine only | no |
| **Project** | `.mcp.json` at the repo root | ✅ committed |
| **User** | your user config | no |

Add one from the CLI:

```bash
claude mcp add my-server -- npx -y @scope/my-mcp-server
```

Manage connections and OAuth from inside a session with `/mcp`.

Example `.mcp.json`:

```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./"]
    }
  }
}
```

> Only add MCP servers you trust — they can read data and run actions.

---

## 4. More settings worth knowing

`settings.json` accepts many keys. Below is a curated set of the most useful
ones for everyday work. For the **exhaustive, always-current list**, see the
official reference: <https://code.claude.com/docs/en/settings>.

### Model & thinking

| Key | Type | What it does |
|-----|------|--------------|
| `model` | string | Default model (read once at startup). |
| `fallbackModel` | array | Fallback chain (up to 3) when the primary is overloaded. |
| `effortLevel` | string | Persist effort: `"low"`, `"medium"`, `"high"`, `"xhigh"`. |
| `alwaysThinkingEnabled` | boolean | Enable extended thinking by default. |
| `maxThinkingTokens` | number | Cap thinking tokens. |

### Git & commits

| Key | Type | What it does |
|-----|------|--------------|
| `includeCoAuthoredBy` | boolean | Add a `Co-Authored-By` trailer to commits (default `false`). |
| `attribution` | object | Customize commit / PR attribution text (or empty it out). |
| `gitCommitTemplate` | string | Template for generated commit messages. |
| `gitPushAutomatically` | boolean | Auto-push after commits (default `false`). |
| `gitRemoteName` | string | Remote used for git operations (default `"origin"`). |

### Session & context

| Key | Type | What it does |
|-----|------|--------------|
| `autoCompactEnabled` | boolean | Auto-compact near the context limit (default `true`). |
| `cleanupPeriodDays` | number | Delete old session transcripts after N days (default `30`). |
| `fileCheckpointingEnabled` | boolean | Snapshot files before edits for `/rewind` (default `true`). |
| `outputStyle` | string | Output formatting style (read at startup). |
| `claudeMdExcludes` | array | Glob patterns of `CLAUDE.md` files to skip. |

### UI & editor

| Key | Type | What it does |
|-----|------|--------------|
| `theme` | string | `"dark"`, `"light"`, or `"auto"`. |
| `editorMode` | string | `"normal"` or `"vim"`. |
| `statusLine` | string/object | Custom status line. |
| `spinnerTipsEnabled` | boolean | Show tips next to the activity spinner. |

### MCP approval

| Key | Type | What it does |
|-----|------|--------------|
| `enableAllProjectMcpServers` | boolean | Auto-approve every server in `.mcp.json`. |
| `enabledMcpjsonServers` | array | Approve specific `.mcp.json` servers only. |
| `disabledMcpjsonServers` | array | Reject specific `.mcp.json` servers. |

### Auth & hooks

| Key | Type | What it does |
|-----|------|--------------|
| `apiKeyHelper` | string | Command that outputs the auth value for API requests. |
| `hooks` | object | Lifecycle hooks around tool calls and events (see below). |

### Environment variables (`env`)

Any variable set here is injected into every session. A few commonly used ones:

| Variable | Purpose |
|----------|---------|
| `DISABLE_AUTO_COMPACT` | Disable auto-compacting. |
| `DISABLE_AUTOUPDATER` | Disable auto-updates. |
| `CLAUDE_CODE_ENABLE_TELEMETRY` | Toggle telemetry. |
| `MAX_THINKING_TOKENS` | Cap thinking tokens (`0` disables). |

```json
{
  "env": {
    "DISABLE_AUTOUPDATER": "1",
    "MY_PROJECT_ENV": "staging"
  }
}
```

### Hooks (quick look)

Hooks let you run your own commands automatically around Claude's actions —
for example, run a formatter after every edit, or block a tool before it runs.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "npx prettier --write $CLAUDE_FILE_PATHS" }
        ]
      }
    ]
  }
}
```

Configure them interactively with `/hooks`. Full reference:
<https://code.claude.com/docs/en/hooks>.

### Permission modes

`permissions.defaultMode` sets how Claude asks before acting. The available
modes evolve across releases — check `/permissions` for what your version
offers. Common values include `default` (ask as needed) and `acceptEdits`
(auto-accept file edits). Prefer tuning via `/permissions` over guessing.

### Enterprise / managed settings

Organizations can enforce policy through **managed settings** that override
everything else (allowlisting MCP servers, pinning versions, injecting an
org-wide `CLAUDE.md`, etc.). These live in OS-specific system paths and are set
by administrators — see the official docs if you manage a fleet.

---

## 5. Choosing global vs. project

| Put it **globally** (`~/.claude/`) when… | Put it in the **project** (`.claude/`) when… |
|------------------------------------------|----------------------------------------------|
| It reflects *your* personal preference. | It reflects a *team* convention. |
| It should follow you across all repos. | It should be shared and versioned. |
| Example: your favorite model, personal commands. | Example: allowed test commands, project `CLAUDE.md`. |

**Rule of thumb:** commit what the team needs, keep personal quirks global, and
put machine-specific or secret-adjacent settings in `*.local.*` files that are
gitignored.

---

## Example files in this repo

- [`.claude/settings.json`](../.claude/settings.json) — a
  starting point you can copy to `.claude/settings.json` or `~/.claude/settings.json`.

See [best-practices.md](best-practices.md) for how to use all of this well.
