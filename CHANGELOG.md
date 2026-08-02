# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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
