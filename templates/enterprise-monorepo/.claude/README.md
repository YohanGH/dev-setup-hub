# `.claude/` — how this configuration is organised

A map for humans. Claude does not load this file; it loads what is described
below, at the moments described below.

## What loads, and when

| Path | Loaded | Cost |
|------|--------|------|
| `../CLAUDE.md` | every session, in full | paid every turn — keep it under ~200 lines |
| `rules/*.md` | when Claude reads a file matching the rule's `paths:` | none until then |
| `skills/*/SKILL.md` | description always; body when relevant or invoked | ~1 line until used |
| `commands/*.md` | body only when you type `/name` | none until then |
| `agents/*.md` | when delegated to | its own context window |
| `conventions/*.md` | **never automatically** — a rule or skill pulls them in | none until pulled |
| `settings.json` | at launch, from the starting directory only | n/a |
| `hooks/*.sh` | never in context — the harness runs them | none |

`conventions/` being un-loaded is deliberate: it is the long-form reference a
human maintains. The one-line enforceable version of each convention lives in
the matching `rules/*.md`, which *is* scoped and loaded.

## Where to put a new instruction

| It is… | Goes in |
|--------|---------|
| Always true, one line | `../CLAUDE.md` |
| True only for some paths | `rules/<topic>.md` with `paths:` |
| Long-form reasoning a human owns | `conventions/<topic>.md` |
| A procedure Claude may pick up on its own | `skills/<name>/SKILL.md` |
| A procedure only you should trigger | same, plus `disable-model-invocation: true` |
| A heavy or noisy sub-task | `agents/<name>.md` |
| Something that must happen every time | a hook in `settings.json` + `hooks/<name>.sh` |
| Something several repos need | a plugin |

Full reasoning: `rules/claude-config.md`, and
[`docs/choosing-a-primitive.md`](../../../docs/choosing-a-primitive.md).

## Directory guide

| Directory | See |
|-----------|-----|
| `commands/` | [`commands/README.md`](commands/README.md) — the pipeline entry points |
| `agents/` | [`agents/README.md`](agents/README.md) — the four subagents and why each field is set |
| `hooks/` | [`hooks/README.md`](hooks/README.md) — events, output contracts, the husky pattern |
| `conventions/` | [`conventions/README.md`](conventions/README.md) — the seven convention files and how they reach Claude |
| `rules/` | one file per area, each with a `paths:` glob |
| `skills/` | the methods, with supporting files under `references/` |
| `scripts/` | callable by you, by hooks, and by git — see `preflight.sh` |
| `sections.json` | per-section architectural boundaries, enforced from anywhere by `hooks/section-dispatch.sh` |
| `tickets/` | generated at runtime: `scope.md`, `review.md`, `report.md`, `commits.log` per ticket |

## Where the per-section configuration lives

Most of this repo's instructions are **not** in this directory — they sit next
to the code they describe:

```text
apps/api/src/routes/.claude/skills/route-handlers/    # loads for route work only
apps/api/.claude/agents/api-debugger.md               # only when started in apps/api
apps/web/src/stores/.claude/skills/state-boundaries/  # loads for store work only
```

That is deliberate, and the direction matters: **skills are discovered downward**
(from the repo root, Claude finds the skills of any subdirectory it touches),
while **subagents and `settings.json` are only found upward** from the working
directory. So a per-package hook is inert for anyone who starts at the root —
put hard rules in `sections.json` instead.

Measure what any of this costs:

```bash
.claude/scripts/context-budget.sh            # whole repo
.claude/scripts/context-budget.sh apps/api   # what a session started there pays
```

## Changing this configuration

It is code that shapes every session — review it like code.

- Test a hook before committing it:
  `echo '<json>' | .claude/hooks/<hook>.sh; echo "exit=$?"`
- Hook changes in `settings.json` need a session restart; plugin changes need
  `/reload-plugins`.
- Never widen `permissions.allow` just to silence a prompt. Add the narrowest
  rule that covers the real command, or leave it in `ask`.
- Personal overrides go in `settings.local.json` (gitignored), never in the
  shared file. See `settings.local.json.example`.
