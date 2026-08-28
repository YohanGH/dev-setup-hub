---
description: Map everything that depends on a symbol, file, or endpoint before changing it
argument-hint: <symbol | path | endpoint>
arguments: target
context: fork
agent: impact-scout
disable-model-invocation: true
---

Map the blast radius of **$target** and report only the conclusion.

Work through `.claude/skills/ticket-analysis/references/impact-checklist.md`
in full. Search before reading; read entry points and their tests first.

Report exactly this, and nothing else:

## Definition
`path/to/file:LINE` — what `$target` is, in one line.

## Direct dependents
| Path:line | How it uses it | Breaks if signature changes? |

Include dynamic references — string keys, DI tokens, route tables, event names,
config values, feature flags. A rename does not surface those.

## Contracts involved
HTTP response · shared type · DB column · event payload · config key · cache
shape. For each: additive change possible, or breaking?

## Tests covering it
| Path:line | What it guarantees |

## Siblings
Other implementations of the same pattern that a reviewer would expect to be
updated in the same change. Find them by grepping a distinctive line, not the
symbol name.

## History
`git log -S"$target"` — the last change that touched it and the constraint that
commit message reveals, if any.

## Verdict
- **Blast radius**: contained to `<package>` | crosses packages | crosses the API contract
- **Safe to change in place**: yes | no, because <reason>
- **Not investigated**: <what you did not cover, and why>

No recommendations, no refactor proposals. This is a map, not a plan.
