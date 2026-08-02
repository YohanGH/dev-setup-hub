<!-- Language: English · [Français](../../docs/fr/example-web-architect.md) -->

# Example — Claude Code for a TypeScript web/app architect

A **concrete, copy-pasteable** Claude Code configuration tuned for one realistic
profile: a web architect building a cross-platform product in TypeScript.

It's here to show the optimization principles from
[`docs/rules-and-skills.md`](../../docs/rules-and-skills.md) applied to a real
stack — a **lean always-on `CLAUDE.md`**, **path-scoped rules** that only load
when relevant, and **commands/skills** for repeatable work — rather than one
giant always-on rules file.

## The profile this targets

| Area | Stack / constraint |
|------|--------------------|
| Language | JavaScript with **TypeScript** everywhere — including config/tooling scripts. |
| Frontend | **Vue 3** in TS, **Quasar** in TS. |
| Backend | **NestJS** in TS, **REST API**. |
| Desktop | **Electron** in TS (Quasar-based), shipping on **Windows / macOS / Linux**. |
| Tooling | Config scripts in TS; team is cross-platform → **cross-platform + backward-compatible** scripts. |
| Package manager | **Migrating npm → yarn** across repos, *not yet 100% done* (mixed state). |
| Testing | Pragmatic — tests must **earn their place** (teams here skip them under time pressure). |
| VCS | git. |

Assumed monorepo layout (adapt paths to yours):

```text
apps/
├── web/        # Vue 3 + Quasar (browser)
├── desktop/    # Electron wrapper (Quasar mode electron)
└── api/        # NestJS REST API
packages/       # shared TS libraries (types, utils)
scripts/        # TS tooling scripts (cross-platform)
```

## What's in here

```text
web-architect-ts/
├── CLAUDE.md                    # Lean always-on memory (the whole team's baseline)
└── .claude/
    ├── settings.json            # Permissions tuned for yarn/npm/git + format-on-edit hook
    ├── rules/                   # Path-scoped — each loads ONLY for matching files
    │   ├── typescript.md        # **/*.ts — TS + cross-platform script rules
    │   ├── vue-quasar.md        # apps/web + *.vue — frontend rules
    │   ├── nestjs-api.md        # apps/api — REST/NestJS rules
    │   ├── electron.md          # apps/desktop — cross-platform desktop rules
    │   ├── package-manager.md   # always on — the yarn-migration policy
    │   └── testing.md           # test files — pragmatic testing policy
    ├── commands/
    │   ├── new-endpoint.md      # /new-endpoint — scaffold a NestJS REST resource
    │   └── migrate-to-yarn.md   # /migrate-to-yarn — npm → yarn for one package
    └── skills/
        └── cross-platform-script/
            └── SKILL.md         # Writing a TS tooling script that runs on Win/mac/Linux
```

## How to use it

1. Copy `CLAUDE.md` and `.claude/` to your repo root.
2. **Adapt the paths** in `CLAUDE.md` and in each `rules/*.md` `paths:` frontmatter
   to your actual folders.
3. Trim anything that doesn't match your reality — this is a starting point, not
   dogma.
4. Commit `.claude/` and `CLAUDE.md`; gitignore `.claude/settings.local.json`.

## Why it's structured this way

- **`CLAUDE.md` stays tiny** — only the always-true baseline. Everything
  stack-specific is a **path-scoped rule**, so the Vue rules don't cost tokens
  when Claude is editing the NestJS API, and vice-versa. That's the core
  optimization: [context isn't free](../../docs/rules-and-skills.md#the-core-tradeoff-context-isnt-free).
- **The yarn-migration policy is a rule, not tribal knowledge** — so Claude picks
  the right package manager per repo during the mixed-state migration.
- **Repeatable work is a command/skill** — `/new-endpoint`, `/migrate-to-yarn`,
  and the cross-platform-script skill load on demand instead of bloating every
  prompt.
