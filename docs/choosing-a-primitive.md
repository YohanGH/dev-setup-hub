<!-- Language: English · [Français](fr/choosing-a-primitive.md) -->

# Choosing a primitive

Claude Code gives you eight places to put a behaviour. Picking the wrong one is
the most common configuration mistake — not because it fails, but because it
works badly and expensively, and nobody notices.

This is the decision guide.

## The one-screen answer

| The behaviour is… | Put it in | Loaded |
|-------------------|-----------|--------|
| Always true, one line, needed every turn | **`CLAUDE.md`** | every session, in full |
| True only for certain paths | **`.claude/rules/*.md`** with `paths:` | when Claude reads a matching file |
| A repeatable procedure Claude should pick up on its own | **Skill** | description always; body only when used |
| A procedure only *you* should trigger | **Skill/command** + `disable-model-invocation: true` | body only when you run it |
| A noisy sub-task worth isolating | **Subagent** | its own context window |
| Must happen every time, whatever the model decides | **Hook** | never — it's a shell command |
| The same rules across many repos | **Plugin** | when enabled |
| Live data or an external system | **MCP server** | on tool call |

**Rule of thumb**: *always-true and tiny → memory. Sometimes-relevant →
skill. Deterministic → hook. Cross-repo → plugin.*

## The trade-off everything hinges on

Context is not free. Anything always-on is paid on **every** request and
competes for attention with the task at hand. A 300-line rules file has two
costs: tokens on every turn, and a diluted signal — the model has to find the
relevant three lines among three hundred.

This is why the maximalist always-on rules file underperforms. The failure mode
is never "too few rules"; it is "too many rules that are rarely relevant".

**Progressive disclosure is the fix.** A skill exposes only its `description` up
front; the body loads when the task matches. That scales to dozens of
capabilities without paying for all of them all the time.

## Memory vs. rules vs. skills

The three get confused constantly. The difference is *when the file's body
enters the context window*.

|  | `CLAUDE.md` | `.claude/rules/x.md` (with `paths:`) | Skill |
|--|-------------|--------------------------------------|-------|
| Body in context | always | when a matching file is read | when invoked or judged relevant |
| Cost when irrelevant | full | zero | ~1 line (the description) |
| Good for | build commands, repo layout, non-negotiables | per-area conventions | procedures, checklists, reference |
| Bad for | anything long or conditional | anything with no natural path scope | facts needed on every turn |

A rule **without** `paths:` loads unconditionally — it is a `CLAUDE.md` entry in
a different file. That is fine for organisation, but it buys you nothing in
context cost. If you wrote a rule to save context, it needs `paths:`.

Two ways to scope by area, both valid:

| | Per-directory `CLAUDE.md` | Path-scoped rule |
|--|---------------------------|------------------|
| Lives | inside the directory, next to its code | centrally in `.claude/rules/` |
| Owned by | that directory's team | whoever owns the config |
| Best when | teams own their own conventions | one rule spans scattered paths |

## Skill vs. command

They are **the same mechanism**. `.claude/commands/deploy.md` and
`.claude/skills/deploy/SKILL.md` both create `/deploy` and take the same
frontmatter. Skills add a directory for supporting files and automatic
invocation.

Use the folders to express intent, as the
[enterprise template](../templates/enterprise-monorepo/) does:

- `commands/` — thin, side-effecting entry points **you** trigger, all with
  `disable-model-invocation: true`.
- `skills/` — the methods and their reference material, which Claude may load on
  its own.

The distinction that actually matters is `disable-model-invocation`. Anything
that writes files, commits, deploys, or messages a human should be yours to
trigger. You do not want Claude deciding the code *looks* ready and shipping it.

## Skill vs. subagent

| | Skill | Subagent |
|--|-------|----------|
| Runs in | your context | its own context window |
| Returns | everything it does | only its summary |
| Has own tools/model/permissions | no | yes |
| Use when | the procedure is short, or you need its output inline | the work is noisy: broad search, whole-diff review, long test output |

The subagent's value is **what you don't see**: fifty greps and reads become one
map. If the sub-task's intermediate output is worthless to you afterwards, it
belongs in a subagent.

You can also get isolation without defining an agent: put `context: fork` on a
skill or command. Add `agent: <name>` to fork into a *specific* subagent — which
is how `/review-scope` stays a three-line command while the reviewer role lives
in one reusable file.

## When it must be a hook

Memory and skills are **context**: Claude reads them and usually complies.
There is no enforcement.

If the answer to "what if Claude doesn't?" is unacceptable, it is a hook. Hooks
are shell commands the harness runs at fixed lifecycle events, regardless of
what the model decides.

Rewrite these as hooks, always:

| Instruction that keeps being written in `CLAUDE.md` | The hook |
|---------------------------------------------------|----------|
| "Always run the tests before committing" | `PreToolUse` on `Bash(git commit *)` |
| "Never edit generated files" | `PreToolUse` on `Edit\|Write` |
| "Format after editing" | `PostToolUse` on `Edit\|Write`, `async` |
| "Don't finish with a broken build" | `Stop` |
| "Tell me the current branch and ticket at startup" | `SessionStart` |

See [hooks-and-automation.md](hooks-and-automation.md).

## Standalone or plugin?

| | `.claude/` in the repo | Plugin |
|--|------------------------|--------|
| Scope | this repo | every repo that enables it |
| Naming | `/deploy` | `/my-plugin:deploy` |
| Updating everywhere | copy-paste, drifts | bump the version |
| Can reference repo-specific conventions | yes | only by deferring to them |
| Best for | project-specific work, fast iteration | shared enforcement, team distribution |

Start standalone. Convert to a plugin when a second repo needs the same thing —
that is the real signal, not the size of the config.

The split that holds up: **repo-specific instructions stay in the repo;
enforcement that should be identical everywhere becomes a plugin.** The
[`review-gate` plugin](../plugins/review-gate/) is the enforcement half of the
enterprise template, made portable — and it defers to the repo's own gate when
one exists, so the local definition always wins.

## And MCP

An MCP server is not a place to put instructions — it is a place to get
**capabilities**: live data, an external API, a search index. Reach for it when
Claude needs something the filesystem cannot answer. Everything above is about
what Claude should *do*; MCP is about what it can *reach*.

## Common mistakes

| Symptom | Actual problem | Fix |
|---------|----------------|-----|
| `CLAUDE.md` past 200 lines | procedures and per-area detail in always-on memory | move to skills and path-scoped rules |
| Claude ignores a rule "sometimes" | it is context, not enforcement | make it a hook |
| A skill never triggers | its `description` doesn't match how anyone phrases the request | rewrite it as the user's words; descriptions are truncated when many exist |
| Reviews read as walls of maybes | the reviewer has `Edit` and no rubric | `disallowedTools: Edit, Write` + a checkable rubric file |
| Permission prompts everywhere | broad `ask` rules | narrow `allow` entries for the exact commands |
| Context fills before the work starts | broad reads, no scoping | per-directory config, `Read` deny rules, subagents for exploration |

## See also

- [frontmatter-reference.md](frontmatter-reference.md) — every field of every file type
- [hooks-and-automation.md](hooks-and-automation.md) — events, contracts, scripts
- [agents-and-autonomy.md](agents-and-autonomy.md) — subagents, background sessions
- [monorepo.md](monorepo.md) — per-directory configuration
- [rules-and-skills.md](rules-and-skills.md) — why not to port a giant `.cursorrules`
