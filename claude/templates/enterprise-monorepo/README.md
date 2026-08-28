<!-- Language: English · [Français](../../docs/fr/template-enterprise-monorepo.md) -->

# Template — enterprise monorepo

A **complete, working** Claude Code setup for a repo with several major
directories and a ticket-driven workflow. Copy it, rename the placeholders, keep
what fits.

It exists to be the shape you reuse across projects with different
architectures: the *structure* is stable, the *content* of each file is what you
adapt per repo.

## What it gives you

| You want | It ships |
|----------|----------|
| Instructions that don't cost context when irrelevant | A lean root `CLAUDE.md`, per-directory `CLAUDE.md`, path-scoped `rules/`, per-directory `skills/` |
| Written conventions a human owns | `.claude/conventions/` — seven files, loaded on demand, never all at once |
| A reproducible ticket workflow | `/ticket` → `/ticket-scope` → `/review-scope` → `/ticket-report`, writing artifacts to `.claude/tickets/<ID>/` |
| A husky-style pre-commit battery | `.claude/scripts/preflight.sh`, enforced for humans **and** for Claude by the same script |
| Isolation for heavy work | Four repo-wide subagents, plus one scoped to `apps/api` |
| Deterministic enforcement | Nine hooks at the root, one per package, one carried by a skill |
| Instructions scoped to a section | Per-section skills under `apps/*/src/*`, and `.claude/sections.json` for boundaries that must hold from anywhere |
| Proof it stays cheap | `.claude/scripts/context-budget.sh` — measures the fixed per-session cost against the total |

## Layout

```text
enterprise-monorepo/
├── CLAUDE.md                        # always-on, < 200 lines
├── .claude/
│   ├── settings.json                # permissions · hooks · worktree · env
│   ├── settings.local.json.example  # personal overrides (gitignored)
│   ├── conventions/                 # long-form, human-owned, loaded on demand
│   │   ├── git.md  code-style.md  testing.md  api-design.md
│   │   └── security.md  review.md  documentation.md
│   ├── rules/                       # path-scoped — load only for matching files
│   │   ├── backend.md  frontend.md  shared-lib.md  tests.md
│   │   └── migrations.md  ci-and-infra.md  claude-config.md
│   ├── commands/                    # you invoke these
│   │   ├── ticket.md  ticket-scope.md  impact.md
│   │   └── review-scope.md  ticket-report.md  preflight.md
│   ├── skills/                      # Claude picks these up
│   │   ├── ticket-analysis/         # + references/ (templates, checklist)
│   │   ├── review-checklist/  handoff-report/  project-conventions/
│   ├── agents/                      # isolated contexts
│   │   ├── impact-scout.md  code-reviewer.md
│   │   └── test-runner.md  ticket-analyst.md
│   ├── hooks/                       # deterministic enforcement
│   │   ├── session-start-context.sh   inject-ticket-context.sh
│   │   ├── pre-commit-gate.sh         protect-paths.sh
│   │   ├── format-edited.sh           post-commit-report.sh
│   │   └── quality-gate.sh
│   ├── scripts/                     # callable by you, by hooks, and by git
│   │   ├── preflight.sh  scan-secrets.sh  context-budget.sh
│   │   ├── ticket-context.sh  install-git-hooks.sh
│   │   └── lib/common.sh
│   └── sections.json                # per-section architectural boundaries
├── apps/api/                        # ← a "major directory"
│   ├── CLAUDE.md
│   ├── .claude/
│   │   ├── settings.json            # package-scoped perms, hooks, plugins, worktree
│   │   ├── agents/api-debugger.md   # only in scope when started here
│   │   ├── hooks/check-contract-sync.sh
│   │   └── skills/{api-testing,new-endpoint,api-design-patterns}/
│   ├── docs/.claude/skills/docs-format/        # ← carries its own hook
│   └── src/                         # ← per-section skills
│       ├── core/.claude/skills/core-boundaries/
│       ├── routes/.claude/skills/route-handlers/
│       ├── services/.claude/skills/service-layer/
│       ├── types/.claude/skills/type-contracts/
│       └── utils/.claude/skills/utils-discipline/
├── apps/web/
│   ├── CLAUDE.md
│   ├── .claude/skills/component-patterns/
│   └── src/
│       ├── api/.claude/skills/data-layer/
│       ├── pages/.claude/skills/page-composition/
│       └── stores/.claude/skills/state-boundaries/
├── packages/shared/
│   ├── CLAUDE.md
│   └── .claude/skills/contract-change/
└── scripts/
    ├── CLAUDE.md
    └── .claude/skills/cross-platform-script/
```

## What this costs

Run the measurement, don't guess:

```console
$ .claude/scripts/context-budget.sh

WHEN IT LOADS                           BYTES   ~TOKENS   FILES
---------------------------------------------------------------
every turn (CLAUDE.md, bare rules)       2528       632       1
skill list (names+descriptions)          5551      1387      19
---------------------------------------------------------------
FIXED COST PER SESSION                   8079      2019
---------------------------------------------------------------
on demand (nested/path-scoped)          14034      3508      11
on use (skill+command bodies)           61137     15284      19
never (conventions, references)         28592      7148      10
---------------------------------------------------------------
TOTAL CONFIG ON DISK                   111842     27960

You pay 7% of this configuration on every turn.
```

Twenty-eight thousand tokens of configuration exist; about two thousand load per
session. Pass a directory (`context-budget.sh apps/api`) to see what one
session actually pays, which subagents are in scope, and whether a
`settings.json` applies there.

## Scoping to one section

Three mechanisms, and they do **not** have the same reach — this is the part
most setups get wrong:

| Scope a… | With | Works from the repo root? |
|----------|------|---------------------------|
| Knowledge | `src/<section>/.claude/skills/` | **yes** — skills are discovered downward |
| Package tooling | `apps/api/.claude/settings.json` hooks, `enabledPlugins` | **no** — only when started in that package |
| Task tooling | `hooks:` in a skill's frontmatter | yes, while that skill is active |
| Hard boundary | `.claude/sections.json` + `section-dispatch.sh` | **yes, always** |
| Autonomy | `apps/api/.claude/agents/` | **no** — agents are found upward from the cwd |

**Skills descend; agents and settings ascend.** So a hard rule — "routes must
not import the data layer" — belongs in `sections.json`, where one root hook
dispatches on the edited path and enforces it whatever the session loaded.
Advisory tooling belongs in the package or the skill, where it costs nothing
when out of scope.

Full reasoning and the measurements:
[`docs/context-economics.md`](../../docs/context-economics.md).

## Install

```bash
cp -r templates/enterprise-monorepo/.claude   /path/to/your/repo/
cp    templates/enterprise-monorepo/CLAUDE.md /path/to/your/repo/
cd /path/to/your/repo
.claude/scripts/install-git-hooks.sh
```

Then:

1. **Replace the placeholders.** `grep -rn '<[A-Z_]*>' .claude CLAUDE.md` finds
   every one: `<TEST_CMD>`, `<DEFAULT_BRANCH>`, `<FRAMEWORK>`, and so on.
2. **Rename the directories.** `apps/api`, `apps/web`, `packages/shared` are
   placeholders for *your* major directories. Update the `paths:` globs in
   `.claude/rules/*.md` and the `sparsePaths` in `settings.json` to match.
3. **Delete what doesn't apply.** A rule for a stack you don't use is worse than
   no rule. This is a starting point, not a checklist to satisfy.
4. **Verify the hooks fire**: `claude --debug`, then edit a file and try a commit.
5. Gitignore `.claude/settings.local.json` and, if you don't want ticket
   artifacts in git, `.claude/tickets/`.

## The ticket workflow

```text
/ticket-scope PROJ-1234     reads the ticket, maps the code    → scope.md
      ↓ (you check the plan)
      implement                                                 → commits.log
      ↓
/review-scope PROJ-1234     reviews vs scope + rubric           → review.md
      ↓
/ticket-report PROJ-1234    hand-off report / PR description    → report.md
```

`/ticket PROJ-1234` runs all four with a checkpoint between each.

Everything lands in `.claude/tickets/PROJ-1234/`. That matters for two reasons:
a long session **compacts its context** and the scope file survives where the
conversation does not; and the artifacts make the run auditable rather than
something you have to take on trust.

`commits.log` is written by a hook, not by the model — so the report is built
from what actually happened.

## The pre-commit battery

One script, three entry points, no drift:

```text
                    .claude/scripts/preflight.sh
                     ↑            ↑            ↑
        .githooks/pre-commit   PreToolUse   your terminal
         (humans commit)     (Claude commits)  (/preflight)
```

- Humans: `install-git-hooks.sh` sets `core.hooksPath`, giving you husky's
  behaviour without the dependency.
- Claude: a `PreToolUse` hook on `git commit` runs the same script and **denies
  the commit** on failure. It also refuses `--no-verify` outright — the one
  thing a human can do and the agent should not.
- The hook detects when git already runs the battery and skips its own run, so
  it never executes twice.

`preflight.sh` detects the stack (npm/yarn/pnpm/bun scripts, ruff/pytest, go,
cargo, Makefile), runs format → lint → typecheck → tests, and always runs a
secret scan over changed files. `--changed` (default) scopes to the diff;
`--all` is what CI runs.

## Where each kind of instruction goes

The decision this template encodes:

| The instruction is… | Put it in | Cost |
|---------------------|-----------|------|
| Always true, one line | `CLAUDE.md` | every turn |
| True for some paths | `.claude/rules/*.md` with `paths:` | only for matching files |
| Long-form reference | `.claude/conventions/` | only when a skill or rule pulls it |
| A procedure Claude may pick up | `.claude/skills/` | only when relevant |
| A procedure only you should trigger | same, `disable-model-invocation: true` | only when you run it |
| A heavy, noisy sub-task | `.claude/agents/` | its own context window |
| Must happen every time | `.claude/hooks/` | none — it's a shell command |
| Shared across repos | a plugin | none until enabled |

Full reasoning: [`docs/choosing-a-primitive.md`](../../docs/choosing-a-primitive.md).

## Turning things off

| Want | Do |
|------|-----|
| No Stop-time gate | `CLAUDE_QUALITY_GATE=off` |
| Hard Stop-time gate | `CLAUDE_QUALITY_GATE=block` |
| No commit gate | `CLAUDE_PRECOMMIT_GATE=off` |
| Full battery on every commit | `CLAUDE_PREFLIGHT_SCOPE=all` |
| All hooks off, temporarily | `"disableAllHooks": true` |

Personal values go in `.claude/settings.local.json`, not the shared file.
