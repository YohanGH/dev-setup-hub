---
description: Testing rules — loaded when touching any test file
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/__tests__/**"
  - "**/test/**"
  - "**/tests/**"
---

# Tests

Full policy: `.claude/conventions/testing.md`. The rules that matter while you
are editing a test file:

- **Never weaken a test to get green.** No loosened assertion, no `skip`, no
  raised timeout, no deleted case. A red test is information — report it and stop.
- A bug fix ships with a test that **fails on the old code**. Write it first and
  show it failing.
- Test names are sentences describing the guarantee:
  `it("rejects an export when the period is still open")`.
- No logic in tests — no loops building expectations, no conditionals.
- Deterministic: freeze the clock, seed randomness, no network, no order
  dependence, no shared mutable fixture.
- Mock at the boundary you own, never the thing under test, never deep inside a
  third-party library.
- Don't test the framework, the ORM, getters, or DTO shape.
