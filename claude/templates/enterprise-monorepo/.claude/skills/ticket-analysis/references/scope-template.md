# Scope — <TICKET-ID>: <ticket title>

- **Source**: <gh issue URL | Jira URL | pasted>
- **Analysed**: <YYYY-MM-DD>
- **Base**: `<branch>` at `<short-sha>`
- **Branch**: `<type>/<TICKET-ID>-<slug>`

## Problem

<Two or three sentences, in the reporter's terms. What is happening, to whom,
and why it matters. No solution here.>

## Acceptance criteria

| # | Criterion | Source | Planned change |
|---|-----------|--------|----------------|
| 1 | <checkable statement> | ticket \| INFERRED | §<n> below |
| 2 | | | |

> Criteria marked `INFERRED` were not in the ticket and need human confirmation.

## Out of scope

- <Explicitly excluded by the ticket>
- <Found during analysis and deliberately not changed — with the reason>

## Impacted code

| Path | Role in this change | Risk |
|------|--------------------|------|
| `apps/api/src/x.ts:42` | <what changes here> | low \| medium \| high |

### Related code not being changed

| Path | Why it matters | Why untouched |
|------|----------------|---------------|
| `packages/shared/src/y.ts:10` | same pattern | out of scope, tracked as <TICKET> |

## Contracts touched

- **API**: <endpoint + additive or breaking>
- **Shared types**: <symbol in packages/shared>
- **Database**: <table/column + migration needed?>
- **Events/config**: <payload or key>

If none: "None."

## Plan

1. <Ordered, each step independently committable and green>
2.
3.

## Tests

| What | Where | New or existing |
|------|-------|-----------------|
| <guarantee being asserted> | `<path>` | new |

Bug fixes: the failing test comes first.

## Risks and rollback

- **Risk**: <what breaks if this is wrong, and who notices>
- **Detection**: <how we would know in production>
- **Rollback**: <revert is enough | needs a data fix, described>

## Decisions

| Decision | Rationale | Alternative rejected |
|----------|-----------|---------------------|
| | | |

## Open questions

- [ ] <Question that changes the implementation, addressed to a person>

## Estimate

- Diff size: ~<n> lines across <n> files.
- Split proposed: yes/no — <if yes, the sequence>
