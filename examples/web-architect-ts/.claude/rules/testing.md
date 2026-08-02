---
paths:
  - "**/*.spec.ts"
  - "**/*.test.ts"
  - "**/*.e2e-spec.ts"
---

# Pragmatic testing

Loads when Claude touches a test file. This team skips tests under time pressure,
so the rule is **not "test everything"** — it's **"test what pays for itself."**

## Worth testing (write these)

- **REST contract**: NestJS e2e tests on each endpoint — status codes, DTO
  validation rejects bad input, the response matches the shared type.
- **Business logic** with real branches: pricing, permissions, state machines,
  anything with `if`s that would be expensive to get wrong.
- **Cross-platform scripts**: a smoke test that the script runs and produces the
  same result regardless of path separator / OS assumptions.
- **Bug regressions**: every fixed bug gets a test that would have caught it.

## Usually not worth it (skip)

- Trivial getters/setters, pass-through DTOs, framework glue with no logic.
- Snapshotting whole Quasar component trees (brittle, low signal).
- Re-testing the framework itself.

## How

- Colocate tests (`*.spec.ts`) next to the code; e2e under the app's `test/`.
- Keep them fast and deterministic — no real network, no real clock, no sleeps.
- A test that's flakier than the code it covers is worse than no test: fix or delete.

> Rule of thumb: if a test would catch a mistake a tired teammate could realistically
> make on a Friday deploy, write it. Otherwise, don't spend the time.
