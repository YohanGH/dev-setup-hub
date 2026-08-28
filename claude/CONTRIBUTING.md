# Contributing to claude-config

First off, thanks for taking the time to contribute! 🎉

This repository is a knowledge base of Claude Code configurations, commands, and
best practices. Contributions that make the content clearer, more accurate, or
more useful are very welcome.

## Code of Conduct

This project and everyone participating in it is governed by our
[Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to
uphold it. Please report unacceptable behavior as described in that document.

## How can I contribute?

- **Fix or improve documentation** — typos, unclear wording, outdated commands.
- **Add a configuration example** — a `settings.json`, `CLAUDE.md`, hook, or
  command that solved a real problem for you.
- **Report an issue** — something wrong, missing, or confusing.
- **Suggest an idea** — open an issue to discuss before large changes.

## Reporting issues

Before opening an issue, please search existing issues to avoid duplicates.
When reporting, include:

- What you expected vs. what happened.
- Steps to reproduce (if applicable).
- Your environment (OS, Claude Code version) when relevant.

## Pull request process

1. **Fork** the repository and create your branch from `main`:
   ```bash
   git checkout -b feat/short-description
   ```
2. **Make focused changes** — one topic per pull request.
3. **Follow the commit convention** (see below).
4. **Keep it consistent** — match the existing tone and formatting; docs are in
   English (the README is bilingual FR/EN).
5. **Open the pull request** with a clear title and description of *what* and
   *why*.

## Commit message convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short summary>
```

Common types: `feat`, `fix`, `docs`, `chore`, `refactor`, `style`, `test`.

Examples:

```
docs: clarify global vs project settings
feat: add example hook for auto-formatting
fix: correct slash command name in commands.md
```

## Style guidelines

- Keep lines reasonably short and prose easy to scan.
- Prefer tables and short lists over long paragraphs.
- Use fenced code blocks with a language tag.
- Link between docs with relative paths.

## Questions?

Open an issue with the `question` label — happy to help.

Thank you! 🙌
