<!-- Language: English · [Français](fr/monorepo.md) -->

# Monorepos & large codebases

The defaults are tuned for small projects. In a large repo they fill the context
window with instructions and file reads unrelated to the task — which costs
tokens and degrades results.

The goal is narrow: **restrict Claude to the part of the codebase the task
touches.** Everything below is one lever toward that. They stack; apply what
your repo needs.

Official guide:
<https://code.claude.com/docs/en/large-codebases>.

## Where you start Claude decides almost everything

| Start from | File access | `CLAUDE.md` loaded | Skills in scope |
|------------|-------------|--------------------|-----------------|
| Repo root | everything | root only; subdirectory files load on demand as it reads there | every subdirectory it touches — can reach hundreds |
| A subdirectory | that subtree | that directory's, plus every ancestor | that directory, its ancestors, plus user and enterprise |

If the work is confined to one package, **start Claude there**. It is the single
most effective thing on this page and it costs no configuration.

One catch that surprises people: `.claude/settings.json` loads **only from your
starting directory**. It is not inherited up the tree the way `CLAUDE.md` files
are. A per-package settings file must be self-contained.

## Layer CLAUDE.md by directory

```text
monorepo/
  CLAUDE.md                  # repo-wide: layout, commit conventions, standards
  packages/api/
    CLAUDE.md                # this package's stack, commands, local rules
    .claude/skills/
  packages/web/
    CLAUDE.md
    .claude/skills/
```

The root file orients: what the packages are, where to run commands. Each
package's file carries its own stack detail. Starting in `packages/api/` loads
root + api, and never `packages/web/`'s conventions.

Keep them alive:

- Review `CLAUDE.md` changes in PRs like any other doc change.
- Revisit after major model releases — a rule that worked around an old
  limitation becomes pure overhead once the model handles it.
- A `Stop` hook can propose updates while the gap that exposed them is fresh.

### Per-directory `CLAUDE.md` or path-scoped rule?

| | Per-directory `CLAUDE.md` | `.claude/rules/*.md` with `paths:` |
|--|---------------------------|-----------------------------------|
| Lives | in the directory, beside its code | centrally at the repo root |
| Loads | at launch when started there; on demand when read | when Claude works with a matching file |
| Best when | directory owners maintain their own conventions | one rule spans scattered paths, or you want all conventions in one place |

Use both. Ownership follows the code; cross-cutting rules stay central.

## Per-directory skills

Any subdirectory can define skills scoped to its own stack. They load on demand,
so API tooling costs nothing during frontend work.

```bash
mkdir -p packages/api/.claude/skills/api-testing
```

```markdown
---
name: api-testing
description: Testing patterns for the API package. Use when writing or changing tests in packages/api/.
---

## Test structure
Tests live in `src/__tests__/` mirroring `src/`...
```

Commit them beside the code they describe. In a monorepo that is one set per
package; in a large single tree, one per subsystem (`src/db/.claude/skills/`).

Alternatively, scope by pattern instead of placement: the `paths:` frontmatter
field takes globs, so a skill in the root `.claude/skills/` can apply only to
`**/migrations/**` wherever those appear.

### Keeping skills discoverable

Claude picks a skill by reading every discovered skill's name and description;
only the chosen one's body loads. With skills scattered across many directories
that list gets long, and **descriptions are truncated when there are many** —
which can cut exactly the keywords that would have matched.

- Start the description with the words a request would contain: *"write or
  change tests in `packages/api`"*, not *"testing utilities"*.
- Skills many directories share — PR conventions, a deploy checklist — go in the
  **root** `.claude/skills/` so they load from any starting directory.
- Shared skills that need their own version history, or must work across repos,
  become a [plugin](../plugins/review-gate/). Plugin skills are namespaced
  `plugin:skill`, so they never collide with per-directory ones.
- To find dead skills: enable the OpenTelemetry logs exporter with
  `OTEL_LOG_TOOL_DETAILS=1` and read the `skill_activated` event.

## Reduce what gets read

Content searches already respect `.gitignore`, so `node_modules/`, `dist/` and
`build/` stay out of results for free. For **committed** generated or vendored
code, add deny rules:

```json
{
  "permissions": {
    "deny": [
      "Read(./**/dist/**)",
      "Read(./**/build/**)",
      "Read(./**/*.generated.*)",
      "Read(./vendor/**)"
    ]
  }
}
```

These cover the built-in file tools and recognised Bash commands (`cat`, `head`,
`grep`, `find`) when a denied path is an argument. They do not filter denied
paths out of a recursive search's output, and they cannot cover an arbitrary
subprocess that opens files itself.

Pair this with a **code-intelligence plugin** so Claude jumps to a definition via
a language server instead of scanning:

```shell
/plugin install typescript-lsp@claude-plugins-official
```

Enable it repo-wide with the `enabledPlugins` project setting. Each developer
needs the language server binary installed.

## Exclude other teams' instructions

Starting from the root, every subdirectory's `CLAUDE.md` loads as soon as Claude
reads a file there. `claudeMdExcludes` skips them permanently:

```json
{
  "claudeMdExcludes": [
    "**/packages/admin-dashboard/**",
    "**/packages/legacy-*/**"
  ]
}
```

Patterns match **absolute** paths, so relative-style patterns must start with
`**/`. Arrays merge across scopes — a team sets defaults in project settings,
individuals add their own locally. Managed-policy `CLAUDE.md` cannot be excluded.

This is a static list, not a per-task switch. To focus on a different package
today, start Claude in that package instead of editing exclusions.

## Sparse worktrees

`--worktree` isolates a session's changes; by default it checks out the whole
repo. In a large repo, list only what's needed:

```json
{
  "worktree": {
    "sparsePaths": [".claude", "packages/api", "packages/shared"],
    "symlinkDirectories": ["node_modules"]
  }
}
```

Root-level *files* (`package.json`, lockfiles, `tsconfig.base.json`) are always
checked out; root-level *directories* are not — **include `.claude` explicitly**
or the repo's settings, rules and skills are missing inside the worktree.

All worktrees in a session share one `sparsePaths`, so list every directory the
parallel subagents need. Settings inside a worktree load from the worktree
root's `.claude/settings.json` — the committed copy of the repo-root file — so
deny rules and hooks need to exist there, not only in a per-package file.

## Working across packages

Starting in `packages/api/`, a change to a shared type needs sibling access:

```json
{ "permissions": { "additionalDirectories": ["../shared", "../web"] } }
```

or at launch: `claude --add-dir ../shared`.

They differ in what comes with the access:

| Added with | Loads `CLAUDE.md` and rules | Loads skills |
|------------|----------------------------|--------------|
| `additionalDirectories` setting | never | never |
| `--add-dir` / `/add-dir` | only with `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` | yes |

For a change spanning packages, two habits matter more than configuration:
**give Claude the whole change in one session** so the decisions behind each edit
stay consistent, and **write the plan to a file first** — a long cross-package
session compacts its context, and the saved plan survives where the conversation
may not. That is exactly what
[`/ticket-scope`](ticket-workflow.md) produces.

## When layering stops scaling

Per-directory files drift, go stale, and nobody owns the root. At that point,
move content out of always-loaded memory and into mechanisms that load on
demand:

- **Skills** — reference material, loaded only when relevant.
- **Plugins** — versioned bundles of skills, hooks and commands a platform team
  owns centrally.
- **MCP servers** — if you already run a code search or RAG index, expose it as
  a tool so Claude queries it instead of reading files.

A `SessionStart` hook can bridge the discovery gap: read the launch directory
from the hook input, look it up in a committed path-to-plugin map, and print the
recommendation — stdout at `SessionStart` becomes context before the first
prompt.

## Putting it together

```text
monorepo/
  CLAUDE.md
  .claude/settings.json                   # deny rules for worktree sessions
  packages/api/
    CLAUDE.md
    .claude/settings.json                 # worktree, additionalDirectories, deny
    .claude/skills/api-testing/SKILL.md
  packages/web/
    CLAUDE.md
    .claude/skills/component-patterns/SKILL.md
  packages/shared/
    CLAUDE.md
```

Starting from `packages/api/`, Claude loads the root and api `CLAUDE.md` and not
web's, reads and edits `api` and `shared`, skips `dist/`, has `api-testing`
available on demand, and creates worktrees containing three directories instead
of the whole tree.

A full working version:
[`templates/enterprise-monorepo`](../templates/enterprise-monorepo/).
