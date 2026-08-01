# Claude Code commands

A practical reference to Claude Code's **slash commands**, grouped by use case,
plus how to write your own.

> Source of truth: <https://docs.claude.com/en/docs/claude-code/slash-commands>.
> Claude Code changes often — run `/help` to see what's available in your
> version.

---

## Built-in slash commands, by use case

### Managing the conversation

| Command | What it does |
|---------|--------------|
| `/clear` | Clear the conversation history and start fresh. |
| `/compact [instructions]` | Summarize and compress the conversation to free up context. Optional instructions steer what to keep. |
| `/cost` | Show token usage and cost for the current session. |
| `/export` | Export the current conversation to a file or clipboard. |
| `/resume` | Resume a previous conversation. |

### Setup & diagnostics

| Command | What it does |
|---------|--------------|
| `/help` | List available commands and usage help. |
| `/status` | Show version, account, and connectivity information. |
| `/doctor` | Check the health of your Claude Code installation. |
| `/config` | Open the settings interface to view or change configuration. |
| `/terminal-setup` | Install the `Shift+Enter` key binding for multi-line input. |
| `/vim` | Toggle vim-style editing mode in the prompt. |

### Account & model

| Command | What it does |
|---------|--------------|
| `/login` | Sign in or switch Anthropic accounts. |
| `/logout` | Sign out of your account. |
| `/model` | Select or change the active model. |

### Project context & memory

| Command | What it does |
|---------|--------------|
| `/init` | Analyze the project and generate a starter `CLAUDE.md`. |
| `/memory` | Open and edit your `CLAUDE.md` memory files. |
| `/add-dir` | Add another working directory to the session. |

### Permissions & tools

| Command | What it does |
|---------|--------------|
| `/permissions` | View or update tool permissions (allow / ask / deny). |
| `/agents` | Create and manage custom subagents. |
| `/hooks` | Configure hooks that run around tool calls and events. |
| `/mcp` | Manage MCP server connections and authentication. |

### Code review & collaboration

| Command | What it does |
|---------|--------------|
| `/review` | Ask Claude to review the current changes. |
| `/pr-comments` | Fetch and act on comments from a GitHub pull request. |
| `/bug` | Report a problem with Claude Code to Anthropic. |

> The exact set of built-in commands can vary between releases. Always trust
> `/help` over any static list.

---

## Custom slash commands

You can define your own commands as Markdown files. The file name becomes the
command name.

| Scope | Location | Shows up as |
|-------|----------|-------------|
| **Project** (shared via git) | `.claude/commands/<name>.md` | `/name` (project) |
| **Personal** (all your projects) | `~/.claude/commands/<name>.md` | `/name` (user) |

Subdirectories create namespaces: `.claude/commands/git/commit.md` →
`/git:commit`.

### Minimal example

`.claude/commands/review-branch.md`:

```markdown
---
description: Review the current branch against main
argument-hint: [base-branch]
allowed-tools: Bash(git diff:*), Bash(git log:*)
model: claude-sonnet-5
---

Review the changes on the current branch compared to `$1` (default `main`).

Current diff:

!`git diff --stat`

Focus on correctness, then readability. Be concise.
```

Run it with:

```
/review-branch main
```

### What you can put in a command

| Feature | Syntax | Purpose |
|---------|--------|---------|
| Frontmatter | `--- ... ---` at the top | Metadata: `description`, `argument-hint`, `allowed-tools`, `model`. |
| All arguments | `$ARGUMENTS` | Everything the user typed after the command name. |
| Positional args | `$1`, `$2`, … | Individual arguments. |
| Bash output | `` !`command` `` | Runs the command and inlines its output (requires `allowed-tools`). |
| File contents | `@path/to/file` | Inlines a file's contents into the prompt. |

### Tips

- Keep one command = one job; compose instead of building a mega-command.
- Add an `argument-hint` so the command is self-documenting in the picker.
- Restrict `allowed-tools` to the minimum a command needs.
- Store team commands in `.claude/commands/` and commit them; keep personal
  ones in `~/.claude/commands/`.

See also [configuration.md](configuration.md) for how commands fit into the
broader configuration model, and [best-practices.md](best-practices.md) for how
to use them well.
