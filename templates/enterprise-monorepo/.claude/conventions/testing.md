# Testing conventions

The policy is **pragmatic, not maximalist**: a test must earn its place by
catching a regression a human would plausibly ship. Coverage percentage is not a
goal and is not a merge gate.

## What must be tested

Non-negotiable — a PR touching these without tests is not done:

1. **Business rules and money/state transitions** — pricing, quotas, permissions,
   anything with an `if` that encodes a domain decision.
2. **Bug fixes** — every fix ships with a test that fails on the old code. Write
   it first, watch it fail, then fix.
3. **API contracts** — request validation, status codes, error shape, auth.
4. **Anything with a non-obvious edge**: empty, one, many, boundary, unicode,
   timezone, concurrent.

## What must not be tested

- Framework behaviour, the ORM, or the standard library.
- Getters, DTO shape, or pure re-exports.
- Snapshot tests of large rendered output — they fail on noise and get blindly
  regenerated, which is worse than no test.
- Private functions directly. Test them through the public entry point; if that
  is impossible, the module boundary is wrong.

## Layout and naming

```text
<package>/
  src/thing.ts
  src/__tests__/thing.test.ts        # mirrors src/ structure
  test/                              # e2e / integration only
  test/fixtures/                     # shared fixtures, no logic
```

Test names are sentences describing the guarantee:

```text
describe("InvoiceExporter")
  it("rejects an export when the period is still open")
  it("includes credit notes in the total")
```

Not `it("works")`, not `it("test 1")`.

## Structure of a test

- **Arrange / Act / Assert**, visually separated by blank lines.
- One behaviour per test. Multiple asserts are fine if they describe one
  behaviour.
- No logic in tests — no loops building expectations, no conditionals. A test
  with a bug is worse than no test.
- Deterministic: freeze time, seed randomness, never depend on test order or on
  a shared mutable fixture.

## Doubles

- Mock at the **boundary you own** (your repository/gateway interface), not deep
  inside a third-party library.
- Never mock the thing under test.
- Integration tests hit a real database in a transaction that rolls back — see
  `<TEST_DB_HELPER>`. Don't mock SQL.

## Running

| Scope | Command |
|-------|---------|
| Everything | `<TEST_CMD>` |
| One package | run from that package's directory |
| One file | `<TEST_CMD> <path>` |
| Watch | `<TEST_CMD> --watch` |
| Changed-only (what preflight uses) | `.claude/scripts/preflight.sh` |

## For Claude specifically

- When fixing a bug, **write the failing test first** and show it failing before
  touching the fix.
- Never weaken an assertion, add a `skip`, or increase a timeout to make a suite
  green. If a test blocks you, say so and stop — a red test is information.
- Never delete a test you didn't write in the same change without saying so
  explicitly in the report.
