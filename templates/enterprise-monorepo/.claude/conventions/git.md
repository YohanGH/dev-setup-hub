# Git conventions

## Branches

```text
<type>/<TICKET-ID>-<short-slug>
```

- `feat/PROJ-1234-invoice-export`
- `fix/PROJ-1290-null-customer-id`
- `chore/PROJ-1301-bump-node-22`

Types: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`, `perf`, `ci`.

Branch from `<DEFAULT_BRANCH>`, rebase onto it before opening the PR. Never
rebase a branch someone else has pulled.

## Commits — Conventional Commits

```text
<type>(<scope>): <imperative summary, no trailing period>

<body: why, not what — the diff already says what>

Refs: <TICKET-ID>
```

Rules:

- **Scope** is the package or area: `api`, `web`, `shared`, `ci`, `deps`.
- Summary in the **imperative**: "add", not "added" or "adds". Max ~72 chars.
- **One concern per commit.** If the body needs "and", split the commit.
- Breaking changes: `feat(api)!: ...` plus a `BREAKING CHANGE:` footer explaining
  the migration.
- Reference the ticket in the footer, not the summary.

Every commit must be independently green: `.claude/scripts/preflight.sh` passes.
A `PreToolUse` hook enforces this for Claude; `.githooks/pre-commit` enforces it
for humans (see `.claude/scripts/install-git-hooks.sh`).

## Pull requests

A PR is reviewable when it has:

1. **Title** = the ticket summary in Conventional Commit form.
2. **What & why** — two or three sentences. Link the ticket.
3. **Scope** — the paths touched and, explicitly, what was deliberately left out.
4. **Risk & rollback** — what breaks if this is wrong, how to revert.
5. **Verification** — the commands run and their result, not "tested locally".

`/ticket-report <TICKET-ID>` generates exactly this from the ticket scope file
and the diff.

Keep PRs under ~400 changed lines where the change allows it. Split refactors
from behaviour changes into separate PRs — a reviewer cannot check both at once.

## Merging

- Squash-merge into `<DEFAULT_BRANCH>`; the squash message is the PR title plus
  the ticket footer.
- Never force-push a shared branch (`permissions.deny` blocks `git push --force`).
- Do not merge your own PR without at least one approving review.

## What Claude does and does not do

- Claude may `add`, `commit`, `stash`, and read history freely.
- `push`, `rebase`, `reset --hard`, `gh pr create` and `gh pr merge` are `ask`.
- Claude never opens or merges a PR unless explicitly told to in that message.
