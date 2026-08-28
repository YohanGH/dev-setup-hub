# Review rubric — the definition of done

This file is the rubric. `/review-scope` reads it and the `code-reviewer`
subagent is judged against it, so keep it **checkable**, not aspirational.

## Severity scale

| Level | Meaning | Merge? |
|-------|---------|--------|
| `blocker` | Wrong behaviour, data loss, security hole, or breaks the contract. | No |
| `major` | Correct today but will break or mislead: missing edge case, silent failure, untested business rule. | No, unless explicitly deferred with a ticket. |
| `minor` | Real but cheap: naming, duplication, a missing comment on a workaround. | Yes, fix in the same PR if trivial. |
| `nit` | Preference. Never blocks. | Yes. |

A finding without a **concrete failure scenario** (inputs → wrong result) is a
`nit` at best. "This could be cleaner" is not a review comment.

## Pass 1 — Scope

- [ ] Every changed file is explained by the ticket. Anything else is scope creep
      and is called out by path.
- [ ] Every acceptance criterion in the ticket is satisfied by something in the
      diff — map criterion → file:line.
- [ ] Nothing in the ticket is silently unimplemented. Missing work is stated,
      not omitted.

## Pass 2 — Correctness

- [ ] Edge cases: empty, single, many, boundary, `null`/absent, duplicate,
      concurrent, retry.
- [ ] Error paths: every failure is handled or deliberately propagated. No empty
      `catch`, no swallowed rejection.
- [ ] State changes are atomic, or the partial-failure path is handled.
- [ ] No off-by-one, no inverted condition, no `==`/`===` slip, no shadowed name.
- [ ] Backwards compatibility: existing callers, stored data, and API clients
      still work. If not, the migration is in the diff.

## Pass 3 — Security

- [ ] Inbound data validated at the boundary.
- [ ] Authorization checked at the resource, not assumed from the route.
- [ ] No secret, token, or personal data in code, logs, or error messages.
- [ ] No string-built SQL/shell/HTML from user input.

## Pass 4 — Tests

- [ ] Business rules touched by the diff have tests.
- [ ] A bug fix has a test that fails without the fix.
- [ ] No test was weakened, skipped, or deleted to get green. If one was, it is
      flagged as a `blocker`.
- [ ] Tests are deterministic (no real clock, no network, no shared mutable state).

## Pass 5 — Conventions and hygiene

- [ ] `git.md`: commit shape, one concern, ticket footer.
- [ ] `code-style.md`: naming, error handling, no commented-out code, no
      untracked `TODO`.
- [ ] `api-design.md` if the diff touches an endpoint: status codes, error shape,
      additive-only change within the version.
- [ ] `documentation.md`: docs/ADR updated when a decision or contract changed.
- [ ] No unrelated reformatting hiding the real change.

## Output format

Findings are reported most-severe first, each as:

```text
[severity] path/to/file.ts:42 — one-sentence defect
  Failure: <concrete inputs/state → wrong output or crash>
  Fix:     <the smallest change that resolves it>
```

Then a verdict line, exactly one of:

- `APPROVE — no blocker or major findings.`
- `REQUEST CHANGES — <n> blocker(s), <n> major.`

Then, always: **what was not reviewed** (files skipped, checks not run, and why).
A review that hides its own gaps is worse than no review.

## Rules for the reviewer

- Verify claims against the code. Do not report a defect you have not traced to
  a line.
- Prefer fewer, certain findings over many speculative ones.
- Never report style the formatter or linter already enforces.
- If the diff is too large to review honestly, say so and ask for a split.
