<!-- Language: English · [Français](fr/agents-and-autonomy.md) -->

# Agents & autonomy

Four different things get called "autonomous". They solve different problems and
they compose:

| Level | What it is | Runs | You see |
|-------|-----------|------|---------|
| **Subagent** | A delegated sub-task inside your session | in its own context window | its summary only |
| **Background task** | A subagent you don't wait for | in parallel, same session | a notification when done |
| **Background session** | A whole independent Claude session | its own process, own worktree | a row in agent view |
| **Scheduled / looping** | A session that starts itself | on a cron or an interval | its output when it runs |

## Subagents

A subagent has its own context window, system prompt, tools and permissions, and
returns only its summary. The value is **what you don't see**: fifty greps and
file reads become one dependency map.

Use one when the sub-task's intermediate output is worthless to you afterwards —
broad search, whole-diff review, long test output, log triage.

Definition and fields: [frontmatter-reference.md](frontmatter-reference.md#subagents-claudeagentsmd).
Worked examples:
[`templates/enterprise-monorepo/.claude/agents/`](../templates/enterprise-monorepo/.claude/agents/).

Three properties do most of the work:

- **`disallowedTools`** — remove the tool rather than asking it not to. A
  reviewer with `Edit` will fix instead of report.
- **`skills`** — preloads the *full* skill body at start, not just its
  description. This is how a reviewer always has the rubric.
- **`model` / `effort`** — searching doesn't need the strongest model; reviewing
  does. Match the spend to the task.

### Subagent or forked skill?

| | Subagent | `context: fork` on a skill/command |
|--|----------|-----------------------------------|
| Reusable by many callers | yes | tied to that one command |
| Own tools, model, permissions | yes | inherits unless it names an `agent:` |
| Best for | a role you invoke repeatedly | one heavy step of one workflow |

Combine them: `context: fork` **plus** `agent: code-reviewer` keeps the command
a thin entry point while the role lives in one reusable file.

### Delegation depends on the description

Claude routes on the `description` field. Write it as the request someone would
actually make:

- Bad: *"Reviews code."*
- Good: *"Use when reviewing a branch or PR, verifying a change before commit,
  or checking work against a ticket's acceptance criteria."*

## Background sessions and agent view

`claude agents` opens a view of every background session: status, what each is
doing, which need input, PR links. Sessions keep running when you close it.

```bash
claude --bg "fix the memory leak in parser"
claude --bg --name "leak-fix" --model opus "refactor auth"
claude agents --permission-mode plan --model opus
```

From inside a session: `/bg <prompt>`. From the view: type a prompt and press
Enter, or `@agent-name <prompt>` to launch a specific subagent as a session.

| Key | Action |
|-----|--------|
| `Space` | preview without attaching |
| `Enter` / `→` | attach |
| `←` | detach |
| `Ctrl+S` | group by state or directory |
| `Ctrl+T` | pin (keeps the process alive) |
| `Ctrl+X` | stop; again to delete |

From the shell: `claude attach <id>` · `claude logs <id>` · `claude stop <id>` ·
`claude agents --json`.

Background sessions create git worktrees under `.claude/worktrees/` so parallel
work doesn't collide. Disable per project with `{"worktree":{"bgIsolation":"none"}}`,
and disable the view entirely with `{"disableAgentView": true}`.

This is what makes backlog triage practical: one session per ticket, all
scoping in parallel, you read four scope files instead of running four
conversations.

```bash
for t in PROJ-1234 PROJ-1235 PROJ-1236; do
  claude --bg --name "scope-$t" "@ticket-analyst scope $t"
done
claude agents
```

## Scheduled and looping work

| Tool | Shape | Good for |
|------|-------|----------|
| `/loop [interval] <prompt>` | repeats in this session | watching a CI run, polling a deploy, iterating until a condition holds |
| `/schedule` | cron-based cloud agent | nightly checks, recurring reports, a one-off "run this at 3pm" |

Both need the same discipline as any unattended job: a clear stop condition, an
output you will actually read, and no destructive side effects.

## Making an agent safe to leave alone

The failure mode of an unattended agent is not that it stops — it is that it
**guesses** and reports confidently. Nobody is there to answer its question, so
it answers it itself.

Design against that:

1. **Say what to do when uncertain.** "Never resolve an ambiguity by assuming.
   List it as an open question addressed to a person." Write this into the agent
   body; it is the single highest-value line in the file.
2. **Make an honest non-result a valid outcome.** A scope file containing only
   *Problem* and *Open questions*, saying the ticket is not scopeable yet, is
   worth more than a confident guess.
3. **Constrain the tools.** `permissionMode: plan` for explorers.
   `disallowedTools` for anything that must not write. Enforcement beats
   instruction.
4. **Bound the run.** `maxTurns` stops a retry loop.
5. **Isolate risk.** `isolation: worktree` gives a refactor its own checkout,
   auto-cleaned if it changes nothing.
6. **Require evidence.** "Every path as `file:line`, verified." An agent that
   cites nothing cannot be checked.
7. **Require a gaps section.** "What was not investigated, and why" — never
   empty. A report that hides its own edges is worse than no report.

## Cost and context

Every subagent is a separate context window with its own token cost. Parallel
agents multiply that. Two habits keep it reasonable:

- Use the cheapest model that does the job — search and log parsing rarely need
  the strongest one.
- Scope what they can reach: `permissions.deny` on build output and vendored
  code, `worktree.sparsePaths` so a worktree checks out three directories
  instead of the whole tree.

## See also

- [choosing-a-primitive.md](choosing-a-primitive.md) — when a subagent beats a skill
- [ticket-workflow.md](ticket-workflow.md) — agents as pipeline steps
- [monorepo.md](monorepo.md) — scoping what agents can see
