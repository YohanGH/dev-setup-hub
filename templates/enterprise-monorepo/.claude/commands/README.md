# Commands

User-invoked entry points. Typing `/<name>` runs the file; `$ARGUMENTS`, `$0`,
or a named `arguments:` placeholder receives what you type after it.

> **Commands and skills are the same mechanism.** `.claude/commands/deploy.md`
> and `.claude/skills/deploy/SKILL.md` both create `/deploy` and support the same
> frontmatter. Skills add a directory for supporting files and are what Claude
> picks up on its own.

## The split used here

| Folder | Holds | Invoked by |
|--------|-------|------------|
| `.claude/commands/` | Thin orchestration with side effects — the pipeline steps you trigger deliberately. All carry `disable-model-invocation: true`. | You only |
| `.claude/skills/` | The methods and their reference material. | Claude, when relevant — or you, by name |

The reason: a command like `/ticket-report` writes files and must run when *you*
decide, not when Claude infers the work looks done. A skill like
`review-checklist` should load automatically the moment a review is happening.

## Available

| Command | Does | Runs as |
|---------|------|---------|
| `/ticket <ID>` | The whole pipeline with four checkpoints. | main thread |
| `/ticket-scope <ID>` | Reads the ticket, maps the code, writes `scope.md`. Stops before editing. | main thread |
| `/impact <target>` | Blast-radius map for a symbol, file, or endpoint. | forked → `impact-scout` |
| `/review-scope <ID>` | Reviews the branch against `scope.md` + the rubric, writes `review.md`. | forked → `code-reviewer` |
| `/ticket-report <ID>` | Writes the hand-off report / PR description. | main thread |
| `/preflight [scope]` | Runs the local quality battery. | main thread |

`/impact` and `/review-scope` set `context: fork` with an `agent:`, so their file
reads never enter your main conversation — you get the conclusion, not the
transcript.

## Writing a new one

```markdown
---
description: One line, imperative — shown in the / menu
argument-hint: <what to type after the command>
arguments: ticket          # then use $ticket in the body
disable-model-invocation: true   # if it has side effects
allowed-tools: Read Grep Bash(git diff:*)
context: fork              # optional: run in a subagent
agent: code-reviewer       # which subagent, when forking
effort: high               # optional
---

Imperative instructions. Reference the skill that holds the method rather than
restating it — commands should stay thin.
```

Checklist before committing one:

- [ ] `description` reads like the request a user would make.
- [ ] Side effects → `disable-model-invocation: true`.
- [ ] Heavy reading → `context: fork` so the main window stays clean.
- [ ] `allowed-tools` is the narrowest set that works — it grants permission.
- [ ] The body says what to do **and where to stop**.
