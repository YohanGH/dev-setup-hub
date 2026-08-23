---
description: Set this template up in the project it was copied into — detect the stack, wire the checks, verify it runs
argument-hint: "[--force]"
arguments: force
disable-model-invocation: true
allowed-tools: Read Grep Glob Edit Write Bash(mkdir:*) Bash(git rev-parse:*) Bash(git status) Bash(git log:*) Bash(ls:*) Bash(cat:*) Bash(${CLAUDE_PROJECT_DIR}/.claude/scripts/checks.sh:*)
---

Set up the spec-driven pipeline in **this** project. Run once, after copying the
template in.

If `.claude/scripts/checks.sh` already has a filled `CONFIGURE` block and
`$force` is not `--force`, stop and show me the current configuration instead.
Re-running this blind overwrites hand-tuned commands.

## 1 — Detect the stack

Read, in this order, and say which ones you found:

| Look at | For |
|---------|-----|
| `package.json` → `scripts` | format, lint, typecheck, test |
| `Makefile` → targets | `fmt`, `lint`, `check`, `test` |
| `pyproject.toml` / `tox.ini` / `noxfile.py` | ruff, black, mypy, pytest |
| `Cargo.toml` | `cargo fmt --check`, `cargo clippy`, `cargo test` |
| `go.mod` | `gofmt -l .`, `go vet`, `go test ./...` |
| `composer.json`, `Gemfile`, `build.gradle`, `*.csproj`, `mix.exs` | the equivalents |
| CI config (`.github/workflows/`, `.gitlab-ci.yml`) | **the authority.** What CI runs is what the battery must run. |

**CI wins every disagreement.** A local battery that is weaker than CI produces
green commits that fail on push, which teaches everyone to stop trusting it.

## 2 — Fill the CONFIGURE block

Write the four commands into `.claude/scripts/checks.sh`:

```bash
FORMAT_CMD=""
LINT_CMD=""
TYPECHECK_CMD=""
TEST_CMD=""
```

Rules:

- **Leave a command empty rather than guessing.** An empty command is reported
  as `skip`, which is honest. A wrong command is reported as `fail`, and someone
  will spend an afternoon on it.
- A language with no typecheck step leaves `TYPECHECK_CMD` empty. That is a
  correct configuration, not a gap.
- Prefer the project's own wrapper (`make lint`, `npm run lint`) over the raw
  tool. It survives a tool change; the raw invocation does not.

## 3 — Verify it actually runs

```bash
.claude/scripts/checks.sh --quick
```

Paste the output. If it exits `2`, nothing was configured — say so plainly
rather than reporting success. If a check fails on a clean tree, that failure is
**pre-existing**: report it, do not fix it, do not weaken it.

## 4 — Wire the paths

| Thing | Default | Adjust to |
|-------|---------|-----------|
| Canonical map | `docs/architecture/map.md` | wherever this project keeps docs — update `commands/spec-map.md` and `templates/09-map.md` together |
| Spec artifacts | `.claude/specs/` | keep, unless the project already has a convention |

Create `.claude/specs/` with a `.gitkeep`.

## 5 — Ask me about the artifacts in git

Do not decide this one. Ask, and wait:

> **Commit the spec artifacts, or gitignore them?**
> Committed: the reasoning is reviewable in the PR and survives the branch —
> and every spec adds ten files to the repo forever.
> Ignored: the repo stays clean — and `10-recap.md` becomes the only trace,
> with nothing behind it once the branch is deleted.

Apply the answer to `.gitignore` and record it in the project's `CLAUDE.md`.

## 6 — Leave a pointer, not a copy

Add to the project's root `CLAUDE.md` — three lines, no more:

```markdown
## Spec-driven pipeline

Feature work runs through `/spec <slug>`. The contract is
`.claude/conventions/pipeline.md`; artifacts live in `.claude/specs/<slug>/`.
Quality battery: `.claude/scripts/checks.sh`.
```

Do not paste the pipeline rules into `CLAUDE.md`. That file is re-read every
session and every line in it is paid for on every turn — a pointer costs three
lines, a copy costs the same tokens forever.

## Output

Report, and nothing else:

| | |
|---|---|
| Stack detected | |
| Commands wired | format · lint · typecheck · tests — with the value of each |
| Left empty | which, and why |
| `checks.sh --quick` | the pasted result line |
| Pre-existing failures | |
| Map path | |
| Artifacts in git | committed / ignored — per my answer |
| Guessed, not verified | **anything you inferred without reading it** |

That last row is the one that matters. A setup that silently guessed wrong is
discovered three phases later, in the middle of something else.

**Stop there.** Do not start a spec. Do not commit — I look at the wiring first.
