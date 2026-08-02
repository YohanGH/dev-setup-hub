<!-- Language: English · [Français](fr/rules-and-skills.md) -->

# Rules & Skills: helpful or counterproductive?

Cursor popularized two ideas: **rules** (`.cursorrules` / project rules that are
always — or conditionally — injected into the prompt) and **skills** (reusable
prompt bundles). A fair question for any Claude Code setup is: *should we add
the same, and does it actually improve performance — or does it get in the way?*

This is the reasoned answer, plus a recommendation for this repo.

---

## The Claude Code equivalents

You don't need to bolt Cursor's concepts onto Claude Code — it already has
first-class primitives that cover the same ground, with different trade-offs:

| Cursor idea | Claude Code equivalent | How it loads |
|-------------|------------------------|--------------|
| Always-on rules (`.cursorrules`) | [`CLAUDE.md`](configuration.md#2-memory-claudemd) memory | **Always** in context |
| Scoped / task rules | [Skills](https://code.claude.com/docs/en/skills), [custom commands](commands.md#custom-slash-commands) | **On demand** (progressive disclosure) |
| Reusable prompt "skills" | Skills, [subagents](commands.md) | Model- or user-invoked |
| Automation | [Hooks](configuration.md#hooks-quick-look) | Event-triggered |

The key difference: `CLAUDE.md` is **always loaded**, while Skills and commands
are loaded **only when relevant**.

---

## The core trade-off: context is not free

Everything you put in an always-on rules file competes for the model's
attention and burns tokens on **every** turn. That has two costs:

1. **Performance** — a large, unfocused ruleset dilutes attention. The model has
   to sift the relevant 3 lines out of 300. Signal drops, mistakes rise.
2. **Money & speed** — always-on context is paid on every request and slows the
   first token.

This is why maximalist `.cursorrules` files (hundreds of lines of aspirational
"always do X, never do Y") often **hurt** more than they help. The failure mode
isn't "too few rules" — it's "too many rules that are rarely relevant."

**Progressive disclosure is the fix.** Skills expose only a short description up
front; their full instructions load *only when the task matches*. That scales to
dozens of capabilities without paying for all of them all the time.

---

## When rules help

Put something in `CLAUDE.md` (always-on) when it is:

- **Stable and high-value** — build/test/lint commands, core conventions.
- **A recurring correction** — something Claude keeps getting wrong here.
- **Short** — a few crisp bullet points, not an essay.
- **Not already enforced elsewhere** — don't restate what the linter/formatter
  or the code itself already guarantees.

## When rules are counterproductive

Avoid always-on rules that are:

- **Long and aspirational** — style manifestos, rarely-triggered edge cases.
- **Task-specific** — "when writing a migration, do X" belongs in a *command* or
  *skill*, not in every prompt.
- **Contradictory or stale** — conflicting guidance is worse than none.
- **Duplicating tooling** — if CI enforces it, you don't also need a rule.

---

## Decision guide: where does a behavior belong?

| You want to… | Use | Why |
|--------------|-----|-----|
| Encode an always-true project fact/convention | `CLAUDE.md` | Needed on every turn, keep it tiny. |
| Package a repeatable, task-specific workflow | **Skill** or **command** | Loads only when relevant — no permanent context cost. |
| Run a large or parallel sub-task in isolation | **Subagent** | Keeps the main context clean. |
| Enforce an action automatically (format, block) | **Hook** | Deterministic, not left to the model. |

**Rule of thumb:** *always-true and tiny → rule. Sometimes-relevant → skill/command.
Deterministic → hook.*

---

## Verdict for this repo

**Adding "rules/skills" is worth it — but only with discipline.** It is not a
question of *whether* but of *which primitive* and *how much*:

- ✅ **Keep a lean `CLAUDE.md`** for the handful of always-true conventions.
- ✅ **Prefer Skills and commands** for anything task-specific — you get Cursor's
  "rules per situation" benefit *without* the always-on context tax.
- ✅ **Use hooks** for things that must happen deterministically.
- ❌ **Don't port a giant `.cursorrules`** verbatim. A 300-line always-on rules
  file is the counterproductive path — it costs tokens every turn and buries the
  signal.

In short: the Cursor instinct (capture your conventions) is right; blindly
copying its *always-on* delivery mechanism is the trap. Claude Code's
progressive-disclosure primitives let you get the upside without the downside.

See also [configuration.md](configuration.md) and [best-practices.md](best-practices.md).
