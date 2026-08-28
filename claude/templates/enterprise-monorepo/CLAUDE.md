# <PROJECT_NAME>

<!-- Always-on memory. Keep under ~200 lines: every line is paid on every turn.
     Stack detail lives in per-directory CLAUDE.md files and .claude/rules/.
     Procedures live in .claude/skills/ and .claude/commands/ (loaded on demand). -->

<ONE_LINE_PURPOSE> — e.g. "Billing platform: REST API, web console, shared TS libs."

## Layout

| Path | What it is | Owner |
|------|------------|-------|
| `apps/api/` | Backend service — see `apps/api/CLAUDE.md` | <TEAM> |
| `apps/web/` | Frontend app — see `apps/web/CLAUDE.md` | <TEAM> |
| `packages/shared/` | Shared libraries consumed by both — see `packages/shared/CLAUDE.md` | <TEAM> |
| `.claude/` | Claude Code configuration — see `.claude/README.md` | <TEAM> |

Run commands from the package directory, not the repo root.

## Commands

<!-- Only the commands that are true repo-wide. Per-package commands belong in
     that package's CLAUDE.md. -->

- Install: `<INSTALL_CMD>`
- Typecheck: `<TYPECHECK_CMD>` — must pass before any commit
- Lint: `<LINT_CMD>` · Format: `<FORMAT_CMD>`
- Test: `<TEST_CMD>`
- Full pre-commit battery: `.claude/scripts/preflight.sh` (see below)

## Always-true conventions

Full conventions live in `.claude/conventions/` and load on demand. The
non-negotiables:

- **Conventional Commits**, imperative mood, scoped: `feat(api): ...`.
- **Never commit without a green preflight** — `.claude/scripts/preflight.sh`
  runs format, lint, typecheck and the scoped tests. A hook enforces it.
- **Never touch secrets** — `.env*`, `*.pem`, `secrets/` are denied at the
  permission layer; don't try to work around it.
- **Small, reviewable diffs**, one concern per commit.
- **Don't push, tag, or open PRs unless asked.**

## Ticket workflow

Work is ticket-driven. The reproducible pipeline is:

1. `/ticket-scope <TICKET-ID>` — read the ticket, map the impacted code, write
   `.claude/tickets/<TICKET-ID>/scope.md`.
2. Implement against that scope file (it survives context compaction).
3. `/review-scope <TICKET-ID>` — review the diff against the ticket's acceptance
   criteria and the conventions.
4. `/ticket-report <TICKET-ID>` — produce the hand-off report.

See `.claude/skills/ticket-analysis/SKILL.md` for the method.

## Where to look

- Per-area conventions: the `CLAUDE.md` inside each package.
- Path-scoped rules: `.claude/rules/` (load only for matching files).
- Repeatable procedures: `.claude/commands/` and `.claude/skills/`.
- Written conventions (long-form): `.claude/conventions/`.
