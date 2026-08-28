# Subagents

Each agent runs in **its own context window** with its own system prompt, tools
and permissions, and returns only its summary. That is the whole point: the
exploration, the diff reads and the test output never enter your conversation.

## The four here

| Agent | Job | Isolation win |
|-------|-----|---------------|
| `impact-scout` | Maps what depends on a symbol/file/endpoint. | Fifty greps and reads → one map. |
| `code-reviewer` | Reviews a diff against `conventions/review.md`. | Whole-branch diff → findings + verdict. |
| `test-runner` | Runs and classifies test failures. | Thousands of lines of output → counts and causes. |
| `ticket-analyst` | Scopes a ticket into `scope.md`. | Backlog triage in parallel, in the background. |

## Properties that matter, and why these use them

| Field | Used by | Why |
|-------|---------|-----|
| `tools` / `disallowedTools` | all | A reviewer that can `Edit` will fix instead of report. Removing the tool is stronger than asking it not to. |
| `permissionMode: plan` | `impact-scout`, `code-reviewer` | Read-only exploration, no prompts, no accidental writes. |
| `skills` | `code-reviewer`, `ticket-analyst` | Preloads the **full** skill body at start, not just its description — the rubric is always there. |
| `model` | `impact-scout` (sonnet), `test-runner` (sonnet) | Search and test-output parsing don't need the strongest model; review does (`inherit`). |
| `effort` | `code-reviewer` (high) | Review is where thinking pays; searching isn't. |
| `memory: project` | `test-runner` | Learns the real test commands, required services, and confirmed-flaky tests across sessions. |
| `background: true` | `ticket-analyst`, `test-runner` | Long jobs you don't want to sit and watch — monitor them with `claude agents`. |
| `maxTurns` | `test-runner` | Hard stop on a loop of re-runs. |
| `color` | all | Distinguishable in the task list and in agent view. |

Other fields worth knowing: `isolation: worktree` (agent gets its own git
worktree — good for a refactor you might throw away), `mcpServers`, `hooks`
(agent-scoped lifecycle hooks), `initialPrompt` (when used as a main-thread agent
via `--agent`).

## Choosing between an agent and a forked skill

| | Subagent (`.claude/agents/`) | `context: fork` on a skill/command |
|---|---|---|
| Reusable across many callers | yes | it's tied to that one command |
| Own tools/permissions/model | yes | inherits, unless it names an `agent:` |
| Best for | a role you invoke repeatedly | one heavy step of one workflow |

`/impact` and `/review-scope` do both: `context: fork` **plus** `agent:`, so the
command stays a thin entry point while the role lives in one place.

## Running them

- Claude delegates on its own when a task matches a `description` — write that
  field as the request a user would actually make.
- Explicitly: `@impact-scout what breaks if I change InvoiceExporter`
- In the background: `claude --bg "@ticket-analyst scope PROJ-1234"`, then
  `claude agents` to watch, `Space` to peek, `Enter` to attach.

## Writing a new one

- The `description` is the routing key. "Reviews code" routes badly; "Use when
  reviewing a branch or PR, or checking work against acceptance criteria" routes
  well.
- Give it the **narrowest** tool set that does the job, then remove what it must
  not do via `disallowedTools`.
- State the output format in the body. An agent whose output shape varies cannot
  be a pipeline step.
- Tell it what to do when it is uncertain — agents run without you, and the
  default failure mode is a confident guess.
