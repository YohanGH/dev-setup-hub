---
name: api-testing
description: Write or change tests in apps/api — HTTP assertions, database fixtures, auth helpers. Use when adding a test for an endpoint, a service, or a repository in the API package.
when_to_use: Triggered while working on any file under apps/api/src/__tests__/ or when adding an endpoint that needs coverage.
allowed-tools: Read Grep Glob Edit Write Bash
---

# Testing the API package

Only loads when work is happening in `apps/api/`. The frontend never pays for
these instructions, and this package never pays for the frontend's.

## Layout

`src/__tests__/` mirrors `src/`. Every route file has a matching `.test.ts`.
Integration tests that need the full app live in `test/`.

## Running

```bash
<TEST_CMD>                                  # all
<TEST_CMD> src/__tests__/routes/users.test.ts   # one file
<TEST_CMD> --watch                          # while iterating
```

Always from `apps/api/`.

## Helpers — use these, don't reinvent them

| Helper | Gives you |
|--------|-----------|
| `src/__tests__/helpers/db.ts` | `setupTestDb()` / `teardownTestDb()` — real database, transaction rolled back after each test |
| `src/__tests__/helpers/auth.ts` | `createTestUser(role)` / `getAuthToken(user)` for authenticated requests |
| `src/__tests__/factories/` | Object factories with sane defaults; override only the field under test |

## What an endpoint test must cover

A test file that only covers the happy path does not count as covered:

1. **Happy path** — correct status, correct body shape.
2. **Validation** — a malformed payload returns `422` with a `details` entry for
   the offending field. Assert the field, not just the status.
3. **Authorization** — an authenticated user without the right returns `403`
   (or `404` where existence is privileged). Assert this even when it feels
   obvious; it is the check most often silently lost in a refactor.
4. **Absence** — unknown id returns `404`.
5. **The domain rule the endpoint exists for** — the actual business assertion.

## Patterns

- Use the HTTP test client for assertions, not a raw fetch — it carries the app
  instance and the auth helpers.
- Assert on the parsed body and the status in the same test. A test asserting
  only `200` documents nothing.
- Wrap every database test in the transaction helper. Never clean up by deleting
  rows — it is order-dependent and it hides leaks.
- Mock outbound third-party calls at the gateway interface in
  `src/__tests__/mocks/`. Never mock the database.
- Freeze time when the assertion involves a timestamp or an expiry.

## Not worth testing here

The framework's routing, the ORM's query builder, DTO shape, or that a getter
returns what was set. Those tests fail on upgrades and catch nothing.
