<!-- Language: English · [Français](fr/context-economics.md) -->

# Context economics: scoping config to a section

Every instruction file has a **load moment** — the point at which its bytes
enter the context window. Design a repo's configuration around those moments
and you can carry a large, detailed setup while paying for very little of it per
turn. Ignore them and you pay for all of it, forever, on every request.

This page is the model, the measurement, and the mechanisms — including the one
asymmetry that determines how per-section configuration actually behaves.

## 1. The five load moments

| Moment | What sits there | Cost profile |
|--------|-----------------|--------------|
| **Every turn** | Root `CLAUDE.md`, `.claude/rules/*.md` **without** `paths:` | Paid on every request, forever |
| **Session index** | Every skill's `name` + `description` + `when_to_use` | Paid once per session, grows with skill count |
| **On demand** | Nested `CLAUDE.md`, path-scoped rules | Only when Claude touches that area |
| **On use** | Skill bodies, command bodies | Only when invoked or judged relevant |
| **Never** | `conventions/`, skill `references/`, docs | Only when something explicitly reads them |

The first two are your **fixed cost**. Everything else is variable and
task-proportional. The entire discipline is: *move bytes down this table.*

## 2. Measure it, don't estimate it

The template ships
[`context-budget.sh`](../templates/enterprise-monorepo/.claude/scripts/context-budget.sh),
which classifies every config file by load moment:

```console
$ .claude/scripts/context-budget.sh

WHEN IT LOADS                           BYTES   ~TOKENS   FILES
---------------------------------------------------------------
every turn (CLAUDE.md, bare rules)       2528       632       1
skill list (names+descriptions)          5551      1387      19
---------------------------------------------------------------
FIXED COST PER SESSION                   8079      2019
---------------------------------------------------------------
on demand (nested/path-scoped)          14034      3508      11
on use (skill+command bodies)           61137     15284      19
never (conventions, references)         28592      7148      10
---------------------------------------------------------------
TOTAL CONFIG ON DISK                   111842     27960

You pay 7% of this configuration on every turn.
```

That is the number that matters: **~28k tokens of configuration exists; ~2k is
loaded per session.** The same content in one always-on file would cost 14× more
per turn *and* bury the relevant three lines in three hundred.

Rules of thumb once you can see the number:

- Fixed cost above **35%** of total → detail is trapped in `CLAUDE.md`; move it
  to path-scoped rules or skills.
- Skill index growing past **~2k tokens** → too many skills in scope. Push them
  into the directories they belong to, or into a plugin.
- `never` bucket near zero → you have no long-form reference, which usually
  means the long-form content is sitting in an always-on file.

Run it with a directory to see what one session actually pays:

```console
$ .claude/scripts/context-budget.sh apps/api
  CLAUDE.md chain loaded at launch: 3973 B (~993 tokens)
  subagents in scope (this dir + ancestors): 1
  skills reachable under this dir: 9
  settings.json: apply here (hooks, plugins, permissions)
```

## 3. The asymmetry that governs everything

Not every mechanism scopes the same direction. This is the single most useful
fact for designing per-section configuration, and it is easy to get wrong:

| Mechanism | From the repo **root** | Started **in the section** |
|-----------|------------------------|----------------------------|
| Nested `CLAUDE.md` | loads on demand when Claude reads there | loads at launch, plus every ancestor |
| Path-scoped rule (`paths:`) | loads on matching file | same |
| **`.claude/skills/`** | **discovered downward** — every subdirectory Claude touches | discovered from here and ancestors |
| **`.claude/agents/`** | **not discovered** — only ancestors of the cwd are scanned | **discovered** |
| **`.claude/settings.json`** (hooks, plugins, permissions) | **not loaded** — start-directory only | **loaded** |

**Skills descend. Agents and settings ascend.**

So a per-package `.claude/settings.json` full of hooks is *inert* for anyone who
runs `claude` at the repo root — which is most people, most of the time. If you
have ever written per-package hooks and wondered why they never fired, this is
why.

Two consequences worth internalising:

- **Skills are the cheap, reliable unit of per-section knowledge.** They work
  from anywhere, they cost one line each until used, and they live next to the
  code they describe.
- **Per-package settings and agents are opt-in by workflow.** They are excellent
  when your team actually starts sessions inside packages — and invisible
  otherwise. Choose them deliberately, not by default.

## 4. Scoping hooks to a section

Three mechanisms, different reach. Pick by whether the rule is *advisory* or
*load-bearing*.

| # | Mechanism | Fires when | Use for |
|---|-----------|-----------|---------|
| 1 | Hook in per-package `settings.json` | session started in that package | package tooling for a team that works inside that package |
| 2 | `hooks:` in a **skill** or **agent** frontmatter | that component is active | advisory tooling naturally tied to a task |
| 3 | One root hook that **dispatches on the file path** | always | hard architectural boundaries |

### (1) Package-scoped

[`apps/api/.claude/settings.json`](../templates/enterprise-monorepo/apps/api/.claude/settings.json)
wires a `PostToolUse` hook that warns when API schemas change without
regenerating the shared types. It also enables the TypeScript language-server
plugin — worth its cost in that package, pointless in a docs session. Both are
inert at the root.

### (2) Component-scoped

A skill can carry its own hooks. The `docs-format` skill declares:

```yaml
hooks:
  PostToolUse:
    - matcher: "Edit|Write|MultiEdit"
      hooks:
        - type: command
          command: "${CLAUDE_PROJECT_DIR}/.claude/hooks/lint-markdown.sh"
          async: true
```

A markdown linter that exists only while someone is writing markdown. All hook
events are supported; for subagents, `Stop` becomes `SubagentStop` automatically;
the hooks are cleaned up when the component finishes.

This is the elegant option — and its weakness is exactly its strength: **if the
skill does not load, the hook does not run.** Never use it for a rule that must
hold.

### (3) Root dispatch — for rules that must hold

The pattern that works everywhere: register **one** hook at the root, and let it
dispatch on the edited path against a committed policy file.

[`.claude/sections.json`](../templates/enterprise-monorepo/.claude/sections.json)
+ [`section-dispatch.sh`](../templates/enterprise-monorepo/.claude/hooks/section-dispatch.sh):

```json
{
  "name": "api/routes",
  "match": "apps/api/src/routes/",
  "skill": "route-handlers",
  "forbid": [
    { "pattern": "from[[:space:]]+['\"][^'\"]*/db[/'\"]",
      "message": "Route handlers must not import the data layer. Call a service." }
  ]
}
```

Editing a route to import the database is denied with the reason and a pointer
to the section's skill — from any starting directory, whether or not that skill
ever loaded. Adding a boundary is a JSON entry; the script never changes.

Two implementation details that matter:

- **Strip comment lines before matching**, or documenting a rule trips it.
- **Match the new content**, from `content` (Write), `new_string` (Edit) and
  `edits[].new_string` (MultiEdit).

## 5. Scoping plugins to a section

`enabledPlugins` lives in `settings.json`, so it follows the same ascend rule:
per-package entries only apply to sessions started there.

| Plugin kind | Where to enable |
|-------------|-----------------|
| Language server for one stack | that package's `settings.json` |
| Org-wide enforcement (a review gate) | repo-root `settings.json` |
| Personal tooling | `~/.claude/settings.json` |

A language server is the clearest case: real value in the package whose language
it serves, pure startup cost everywhere else.

Plugins also solve the *other* scaling problem. Per-directory skills stop scaling
when the same skill is copied into six repos — at that point version it as a
plugin. Plugin skills are namespaced `plugin:skill`, so they never collide with
per-directory ones.

## 6. Scoping autonomy to a section

Subagents are the largest single lever on context, because their reads never
enter your window at all. Scoping them per section:

- **Package-level agents** (`apps/api/.claude/agents/api-debugger.md`) are
  discovered by walking **up** from the cwd. Start in `apps/api/` and you get the
  API debugger; start at the root and you do not. That is correct — a backend
  debugger is noise during frontend work.
- **Nearest definition wins.** Two packages can each define an agent named
  `debugger` with different instructions; whichever is closest to the working
  directory is used.
- **Repo-level agents** (`impact-scout`, `code-reviewer`) stay at the root
  because their job is inherently cross-section.
- **`skills:` preloading** injects a skill's full body into an agent at start —
  how a reviewer always has the rubric without it being in your context.
- **Background sessions inherit the directory they were launched from**, so
  `cd apps/api && claude --bg "..."` gets that package's settings, hooks and
  agents. That is the cleanest way to run a section-scoped autonomous task.

## 7. The playbook

Ordered by return on effort:

1. **Start Claude in the section you are working on.** Zero configuration,
   biggest single win: ancestors only, no sibling packages, no unrelated skills.
2. **Split `CLAUDE.md` per directory.** Root keeps layout and repo-wide rules;
   each package keeps its own stack detail.
3. **Move procedures into skills, placed in the directory they serve.** Costs a
   description; buys the whole body on demand.
4. **Move long-form reference into `conventions/`**, pulled in by a rule or
   skill. Never loaded until needed.
5. **Deny reads** of `dist/`, `build/`, generated and vendored code. Search hits
   that never become reads.
6. **Delegate exploration** to a read-only subagent. Fifty file reads become one
   summary.
7. **Add a code-intelligence plugin** so definitions are looked up, not scanned.
8. **Sparse worktrees** so a background session checks out three directories.
9. **Trim the skill index**: audit with `skill_activated` telemetry
   (`OTEL_LOG_TOOL_DETAILS=1`) and delete or consolidate what never fires.

## 8. Anti-patterns

| Anti-pattern | Why it costs | Instead |
|--------------|--------------|---------|
| One 400-line root `CLAUDE.md` | paid every turn; buries the relevant lines | split per directory + path-scoped rules |
| Rules with no `paths:` | loads unconditionally — it is `CLAUDE.md` in another file | add `paths:`, or admit it belongs in memory |
| A skill per micro-topic | index grows, descriptions get truncated, matching degrades | one skill per section, with sections inside it |
| Per-package hooks for a hard rule | inert from the root — silently never runs | root dispatch on file path |
| Vague descriptions ("testing utilities") | never matches a real request | the user's words: "write or change tests in `packages/api`" |
| Duplicating a skill across repos | drifts immediately | version it as a plugin |
| Long preamble in a `SessionStart` hook | stdout becomes context, every session | print state, not advice |

## See also

- [monorepo.md](monorepo.md) — the mechanics: `claudeMdExcludes`, sparse
  worktrees, cross-package access
- [choosing-a-primitive.md](choosing-a-primitive.md) — which primitive for which
  behaviour
- [hooks-and-automation.md](hooks-and-automation.md) — hook contracts and
  scripts
- [agents-and-autonomy.md](agents-and-autonomy.md) — subagents and background
  sessions
