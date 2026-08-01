# Configuring Claude Code

Everything you can hand to Claude Code to shape how it behaves — for a single
project or globally across all of them.

> Source of truth: <https://docs.claude.com/en/docs/claude-code/settings>.

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

## 4. Choosing global vs. project

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

- [`.claude/settings.example.json`](../.claude/settings.example.json) — a
  starting point you can copy to `.claude/settings.json` or `~/.claude/settings.json`.

See [best-practices.md](best-practices.md) for how to use all of this well.
