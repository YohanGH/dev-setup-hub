<!-- Language: English · [Français](fr/best-practices.md) -->

# Best practices with Claude Code

Opinionated, practical advice that isn't strictly "configuration" but makes the
biggest difference in day-to-day use. Adopt what fits.

---

## 1. Give Claude the right context

- **Maintain a `CLAUDE.md`.** It's the single highest-leverage thing you can do.
  Put in conventions, how to run tests/lint/build, and any rule Claude keeps
  missing. See [configuration.md](configuration.md#2-memory-claudemd).
- **Point, don't paste.** Reference files with `@path/to/file` instead of
  copying big blobs into the prompt.
- **Be specific about the goal**, not the keystrokes. "Make the login form
  validate email and show inline errors" beats "edit line 42".

## 2. Manage the context window

- Use **`/clear`** between unrelated tasks. A fresh context is faster and more
  accurate than a cluttered one.
- Use **`/compact`** when a long task is still going but the history is bloated.
- Long, wandering sessions degrade quality — split work into focused chunks.

## 3. Work in small, verifiable steps

- Ask for a **plan first** on anything non-trivial, review it, then execute.
- Prefer **one change at a time**; verify (tests, run the app) before moving on.
- Let Claude **run the tests** and read the output — closing the loop beats
  guessing.

## 4. Be deliberate about permissions

- Start stricter, loosen as you build trust. Use `/permissions` to tune.
- **Allow** the safe, repetitive commands (`git status`, your test runner) so
  you're not clicking "approve" all day.
- **Deny** reads of secrets: `.env`, `secrets/**`, key files.
- Reserve broad or destructive commands for **ask** so you stay in the loop.
- See the example [`.claude/settings.example.json`](../.claude/settings.example.json).

## 5. Never leak secrets

- Keep secrets out of `settings.json`, `CLAUDE.md`, commands, and the prompt.
- Use placeholders (`<YOUR_API_KEY>`) in anything you commit.
- Gitignore `*.local.*` files and `.env*`. This repo's [.gitignore](../.gitignore)
  already does.

## 6. Use custom commands for repeated workflows

- Turn any prompt you type more than twice into a
  [custom command](commands.md#custom-slash-commands).
- Keep them **small and composable**; add an `argument-hint`.
- Commit team commands under `.claude/commands/`; keep personal ones in
  `~/.claude/commands/`.

## 7. Use subagents for big, parallelizable work

- Delegate broad searches or independent sub-tasks to **subagents** (`/agents`)
  so the main context stays clean.
- Give each subagent a **narrow, well-scoped** brief and relay only the result.

## 8. Keep a tidy git workflow

- Let Claude write focused commits with clear messages (Conventional Commits).
- **Review the diff** before committing — you own the code, not the model.
- Commit **often and small**; it makes mistakes cheap to undo.
- Don't push or open PRs unless you asked for it.

## 9. Trust, but verify, external tools

- Only add **MCP servers** you trust — they can read data and take actions.
- Review **hooks** and shell commands before enabling them; they run on your
  machine.

## 10. Treat output as a draft to review

- Claude is a fast, capable collaborator — not an oracle. **Read what it wrote.**
- When it's wrong, encode the correction in `CLAUDE.md` so it doesn't recur.
- If a session goes sideways, `/clear` and restate the goal cleanly rather than
  fighting the context.

---

## Quick checklist

- [ ] Project has a lean, accurate `CLAUDE.md`.
- [ ] Test / lint / build commands are documented and allowed.
- [ ] Secrets are denied and gitignored.
- [ ] Repeated prompts are turned into commands.
- [ ] You `/clear` between unrelated tasks.
- [ ] You review diffs before they're committed.

See also [configuration.md](configuration.md) and [commands.md](commands.md).
