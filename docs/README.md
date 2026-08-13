<!-- Language: English · [Français](fr/README.md) -->

# Documentation

Knowledge base for configuring and getting the most out of
[Claude Code](https://code.claude.com/docs/en/overview).

> Available in English and French (`fr/`). The project [README](../README.md)
> is bilingual (FR/EN).

## Index

### Fundamentals

| Guide | What you'll find |
|-------|------------------|
| [configuration.md](configuration.md) | The full configuration model: global vs. project vs. local, `settings.json`, `CLAUDE.md` memory, permissions, hooks, and MCP servers. |
| [claude-directory.md](claude-directory.md) | Annotated map of the `.claude/` directory — project vs. `~/.claude/`, with a full directory tree and what each file/folder is for. |
| [commands.md](commands.md) | Reference of Claude Code slash commands, grouped by use case, plus how to write your own custom commands. |
| [best-practices.md](best-practices.md) | Practical, opinionated tips that make a real difference when working with Claude Code every day. |

### Designing a setup

| Guide | What you'll find |
|-------|------------------|
| [choosing-a-primitive.md](choosing-a-primitive.md) | **Start here.** Memory, rules, skills, commands, subagents, hooks, plugins, MCP — which one for which behaviour, and why the wrong choice is expensive. |
| [frontmatter-reference.md](frontmatter-reference.md) | Every field of every configurable file type, plus the *optimal properties* per job. |
| [rules-and-skills.md](rules-and-skills.md) | Should you add Cursor-style rules/skills? A reasoned take, with a decision guide. |
| [monorepo.md](monorepo.md) | Large codebases: per-directory `CLAUDE.md` and skills, `claudeMdExcludes`, sparse worktrees, cross-package work. |
| [context-economics.md](context-economics.md) | What your configuration actually costs per turn, how to measure it, and how to scope hooks, plugins and autonomy to one section of the repo. |

### Automating

| Guide | What you'll find |
|-------|------------------|
| [hooks-and-automation.md](hooks-and-automation.md) | Hook events, input/output contracts, the husky-style pre-commit pattern, and the shell scripts worth having. |
| [agents-and-autonomy.md](agents-and-autonomy.md) | Subagents, background tasks, background sessions and agent view, scheduled work — and how to make an agent safe to leave alone. |
| [ticket-workflow.md](ticket-workflow.md) | A reproducible ticket pipeline: scope → implement → review → report, with artifacts instead of recollection. |

### Ready-made configurations

| | What it is |
|--|-----------|
| [template: enterprise monorepo](../templates/enterprise-monorepo/README.md) | A complete working setup for a multi-directory, ticket-driven repo: conventions, path-scoped rules, per-directory skills, four subagents, seven hooks, and a pre-commit battery shared by humans and Claude. |
| [plugin: review-gate](../plugins/review-gate/README.md) | The same quality gate as a portable, versioned plugin. |

## How to use these docs

1. Start with [configuration.md](configuration.md) to understand *where* config
   lives and *how* it is layered.
2. Read [choosing-a-primitive.md](choosing-a-primitive.md) before writing any
   config — it is the decision that everything else follows from.
3. Copy [the template](../templates/enterprise-monorepo/README.md) and adapt it,
   rather than building from an empty directory.
4. Adopt what fits from [best-practices.md](best-practices.md).

Everything here is meant to be **copied and adapted** — take what is useful for
your own `~/.claude/` (global) or project `.claude/` setup.

## Official references

- Claude Code documentation: <https://code.claude.com/docs/en/overview>
- Slash commands: <https://code.claude.com/docs/en/slash-commands>
- Settings: <https://code.claude.com/docs/en/settings>
- Memory (`CLAUDE.md`): <https://code.claude.com/docs/en/memory>
- Hooks: <https://code.claude.com/docs/en/hooks>
- MCP: <https://code.claude.com/docs/en/mcp>

> Claude Code evolves quickly. When in doubt, the official documentation above
> is the source of truth; this repo is a curated, practical companion.
