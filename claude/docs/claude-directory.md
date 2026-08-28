<!-- Language: English · [Français](fr/claude-directory.md) -->

# The `.claude` directory

Claude Code reads its configuration from **two `.claude` locations** that layer
together:

- **Project** — `.claude/` at your repo root: what the *team* shares (committed).
- **User / global** — `~/.claude/` in your home dir: *your* setup across every
  project (never committed).

This page maps out what lives in each, so you know where to put a given piece of
configuration.

> Source of truth: <https://code.claude.com/docs/en/claude-directory>.

---

## The three "badges"

Every file below is one of:

| Badge | Meaning | Commit to git? |
|-------|---------|----------------|
| **committed** | Shared with the team through source control. | ✅ yes |
| **gitignored** | Yours, project-specific, kept out of git. | ❌ no (gitignore it) |
| **local** | Lives under `~/.claude/`, personal to your machine. | n/a |

---

## Project `.claude/` (shared with the team)

Everything here is versioned so the whole team gets the same Claude Code setup.

```text
your-project/
├── CLAUDE.md                  # committed  · Instructions Claude reads every session
├── .mcp.json                  # committed  · Project-scoped MCP servers, shared with the team
├── .worktreeinclude           # committed  · Gitignored files to copy into new worktrees
└── .claude/
    ├── settings.json          # committed  · Permissions, hooks, model, env
    ├── settings.local.json    # gitignored · Your personal overrides for THIS project
    ├── rules/                 # Topic-scoped instructions, optionally gated by file paths
    │   ├── testing.md         # committed  · e.g. test conventions scoped to test files
    │   └── api-design.md      # committed  · e.g. API conventions scoped to backend code
    ├── skills/                # Reusable prompts you or Claude invoke by name
    │   └── security-review/   # A skill = a folder bundling SKILL.md + supporting files
    │       ├── SKILL.md       # committed  · Entrypoint: trigger, invocability, instructions
    │       └── checklist.md   # committed  · Supporting file bundled with the skill
    ├── commands/              # Single-file slash commands
    │   └── fix-issue.md       # committed  · Invoked as /fix-issue
    ├── agents/                # Specialized subagents, each with its own context window
    │   └── code-reviewer.md   # committed  · Subagent for isolated code review
    ├── output-styles/         # Project-scoped output styles, if your team shares any
    ├── workflows/             # Dynamic workflow scripts that orchestrate many subagents
    └── agent-memory/          # committed  · Subagent persistent memory (Claude-maintained)
        └── <agent-name>/
            └── MEMORY.md
```

### What each piece is for

| Path | Purpose |
|------|---------|
| `CLAUDE.md` | Always-on project memory (conventions, commands, architecture). Loaded every session — keep it lean. See [configuration.md](configuration.md#2-memory-claudemd). |
| `.mcp.json` | Extra tools (databases, browsers, trackers) shared with the team. |
| `.claude/settings.json` | Permissions, hooks, model, env — the shared behavior contract. |
| `.claude/settings.local.json` | Your machine-specific overrides. **Gitignore it.** |
| `.claude/rules/` | Instructions split by topic; add `paths:` frontmatter to load them only for matching files. Great for large repos. |
| `.claude/skills/` | Repeatable workflows loaded **on demand** — the low-context way to add capability (see [rules-and-skills.md](rules-and-skills.md)). |
| `.claude/commands/` | Single-file custom slash commands (see [commands.md](commands.md#custom-slash-commands)). |
| `.claude/agents/` | Subagents with isolated context for big/parallel sub-tasks. |
| `.claude/agent-memory/` | Where subagents keep their own auto-memory. |

---

## User `~/.claude/` (personal, all projects)

Your global setup — preferences and extensions that follow you across every repo.
Nothing here is committed to any project.

```text
~/
├── .claude.json               # local · App state and UI preferences
└── .claude/
    ├── CLAUDE.md              # local · Personal preferences across every project
    ├── settings.json          # local · Your default settings for all projects
    ├── keybindings.json       # local · Custom keyboard shortcuts
    ├── themes/                # local · Custom color themes
    ├── rules/                 # local · User-level rules applied to every project
    ├── skills/                # local · Personal skills available everywhere
    ├── commands/              # local · Personal single-file commands available everywhere
    ├── output-styles/         # local · Custom system-prompt sections (e.g. teaching.md)
    ├── agents/                # local · Personal subagents available everywhere
    ├── workflows/             # local · Personal dynamic workflows
    └── projects/
        └── <project>/memory/  # Auto-memory Claude writes for itself, per repo
            ├── MEMORY.md      # local · Concise index, loaded every session (first 200 lines / 25 KB)
            └── debugging.md   # local · Topic notes Claude spins out when MEMORY.md grows
```

> `~/.claude/projects/<project>/memory/` is **auto-memory**: Claude writes it
> itself from your corrections. `MEMORY.md` is capped at the first **200 lines /
> 25 KB** at load — unlike `CLAUDE.md`, which always loads in full (see
> [configuration.md](configuration.md#how-big-can-a-claudemd-be)).

---

## Project vs. user: where does it go?

The same folder names (`rules/`, `skills/`, `commands/`, `agents/`) exist in both
locations. The rule of thumb:

| Put it in **`.claude/`** (project) when… | Put it in **`~/.claude/`** (user) when… |
|------------------------------------------|-----------------------------------------|
| The team needs it and it should be versioned. | It's a personal preference. |
| It's tied to *this* codebase. | It should follow you across all repos. |
| e.g. project `CLAUDE.md`, allowed test commands, a repo-specific skill. | e.g. your model, keybindings, personal commands. |

User-level rules load **before** project rules, so project settings take priority
when they overlap.

---

See [configuration.md](configuration.md) for the settings model and
[commands.md](commands.md) for commands, skills, and subagents in depth.
