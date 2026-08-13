# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `templates/enterprise-monorepo/` — a complete, working Claude Code setup for a
  multi-directory, ticket-driven repository, meant to be copied and adapted per
  project:
  - `.claude/conventions/` (7 files) — long-form, human-owned conventions
    (git, code style, testing, API design, security, review rubric,
    documentation), loaded on demand rather than always-on.
  - `.claude/rules/` (7 files) — path-scoped rules carrying the one-line
    enforceable form of those conventions, including a meta-rule for editing the
    Claude configuration itself.
  - `.claude/commands/` — the ticket pipeline: `/ticket`, `/ticket-scope`,
    `/impact`, `/review-scope`, `/ticket-report`, `/preflight`.
  - `.claude/skills/` — `ticket-analysis` (with a scope template and an impact
    checklist), `review-checklist`, `handoff-report`, `project-conventions`.
  - `.claude/agents/` — `impact-scout`, `code-reviewer`, `test-runner`,
    `ticket-analyst`, each with tool, model and permission scoping.
  - `.claude/hooks/` (7 scripts) — `SessionStart` context, `UserPromptSubmit`
    ticket-context injection, a `PreToolUse` commit gate that refuses
    `--no-verify`, protected-path guard, async formatting, commit logging, and a
    loop-safe `Stop` quality gate.
  - `.claude/scripts/` — `preflight.sh` (stack-detecting format/lint/typecheck/
    test battery), `scan-secrets.sh`, `ticket-context.sh`,
    `install-git-hooks.sh`, and a shared `lib/common.sh`.
  - Per-directory configuration for `apps/api`, `apps/web`, `packages/shared`
    and `scripts/`: nested `CLAUDE.md` files, per-package `settings.json`, and
    per-directory skills.
  - **Per-section configuration inside each app**, so instructions load only
    for the part of the tree being worked on: `apps/api/src/{core,routes,
    services,types,utils}` and `apps/api/docs`, plus `apps/web/src/{pages,
    stores,api}`, each with its own scoped skill.
  - **Section-scoped enforcement from the repo root**: `.claude/sections.json`
    declares per-directory architectural boundaries (routes must not import the
    data layer, services must not know about HTTP, utils must stay pure,
    components must not fetch, migrations must not drop), enforced by a single
    `PreToolUse` dispatcher in `.claude/hooks/section-dispatch.sh` that works
    from any starting directory.
  - **Package-scoped autonomy and tooling**: `apps/api/.claude/agents/api-debugger.md`,
    a package-scoped `PostToolUse` contract-sync hook, and a package-scoped
    `enabledPlugins` entry — all deliberately inert outside that package.
  - **A skill-scoped hook**: the `docs-format` skill carries its own
    `PostToolUse` markdown linter in frontmatter, so it exists only while
    documentation is being written.
  - `.claude/scripts/context-budget.sh` — classifies every config file by when
    it enters the context window and reports the fixed per-session cost against
    the total. The shipped template measures at ~7% fixed.
  - Overview docs in EN (`templates/.../README.md`) and FR
    (`docs/fr/template-enterprise-monorepo.md`).
- `docs/context-economics.md` (EN + FR) — the five load moments, how to measure
  a configuration's real per-turn cost, the **scope asymmetry** (skills are
  discovered downward from the root; subagents and `settings.json` only upward
  from the working directory), the three ways to scope hooks to a section and
  their differing reach, and a playbook ordered by return on effort.
- `plugins/review-gate/` — the same quality gate packaged as a portable,
  versioned plugin (manifest, `hooks/hooks.json`, a single `guard.sh` with
  commit/write/stop modes, a skill and a `diff-reviewer` agent), plus
  `plugins/.claude-plugin/marketplace.json` as a local marketplace. The plugin
  defers to a repo's own `preflight.sh` when one exists.
- `docs/choosing-a-primitive.md` (EN + FR) — which primitive for which
  behaviour: memory, path-scoped rules, skills, commands, subagents, hooks,
  plugins and MCP, with the context-cost reasoning and the common mistakes.
- `docs/frontmatter-reference.md` (EN + FR) — every field of every configurable
  file type (skills/commands, subagents, rules, hooks, settings, plugin and
  marketplace manifests), plus the optimal properties per job.
- `docs/hooks-and-automation.md` (EN + FR) — hook events, input and output
  contracts, the husky-style one-script/three-entry-points pre-commit pattern,
  loop-safe `Stop` hooks, and the shell scripts worth having.
- `docs/agents-and-autonomy.md` (EN + FR) — subagents, background tasks,
  background sessions and agent view, scheduled/looping work, and how to make an
  unattended agent report honestly instead of guessing.
- `docs/ticket-workflow.md` (EN + FR) — a reproducible ticket pipeline
  (scope → implement → review → report) built on file artifacts that survive
  context compaction.
- `docs/monorepo.md` (EN + FR) — large-codebase configuration: per-directory
  `CLAUDE.md` and skills, keeping skills discoverable, `Read` deny rules,
  `claudeMdExcludes`, sparse worktrees, and cross-package work.
- `docs/claude-directory.md` (EN + FR) — an annotated map of the `.claude/`
  directory tree for both project and `~/.claude/` scopes, with a "where does it
  go?" guide.
- `CLAUDE.md` size guidance in `configuration.md` and `best-practices.md`
  (EN + FR): no hard limit, target under ~200 lines, and how the 200-line / 25 KB
  cap only applies to auto-memory `MEMORY.md`.
- French translation of the docs under `docs/fr/`, with language navigation
  links between the English and French versions.
- `docs/rules-and-skills.md` — a reasoned take on whether to adopt Cursor-style
  rules/skills, with a decision guide (EN + FR).
- Expanded `docs/configuration.md` with a curated set of `settings.json` keys
  (model, git, session, UI, MCP approval, env vars, hooks) sourced from the
  official settings documentation.

### Changed

- Updated documentation links to the `code.claude.com/docs` domain.
- Repointed the `settings.example.json` references in `configuration.md` and
  `best-practices.md` (EN + FR) to `.claude/settings.json`, completing a rename
  that had left four broken links.

### Removed

- `examples/` — superseded by `templates/enterprise-monorepo/`, which covers the
  same ground with a complete, tested configuration. The parts worth keeping
  were folded into the template rather than dropped: the per-directory skill
  scaffolding under `examples/web-architect-ts/src/*` became the realised
  `apps/api/src/*` and `apps/web/src/*` sections, and the cross-platform script
  skill became `scripts/.claude/skills/cross-platform-script/`. The FR overview
  page `docs/fr/example-web-architect.md` went with it.

## [0.1.0] - 2026-08-01

### Added

- Initial repository structure and community health files.
- `.gitignore` with common ignore rules (OS, editors, secrets, logs, builds).
- Bilingual (FR/EN) `README.md`.
- MIT `LICENSE.md`.
- `CONTRIBUTING.md` and `CODE_OF_CONDUCT.md` (Contributor Covenant).
- `SECURITY.md` with a responsible disclosure policy.
- `docs/` knowledge base:
  - `commands.md` — Claude Code slash commands reference.
  - `configuration.md` — global / project / local configuration guide.
  - `best-practices.md` — practical tips for working with Claude Code.

[Unreleased]: https://github.com/YohanGH/claude-config/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/YohanGH/claude-config/releases/tag/v0.1.0
