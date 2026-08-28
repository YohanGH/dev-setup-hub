---
description: Database migration safety — loaded when touching a migration file
paths:
  - "**/migrations/**"
  - "**/migrate/**"
  - "**/*.migration.*"
---

# Migrations

A migration runs once, against production data, usually while the old code is
still serving traffic. Treat every one as irreversible.

- **Never edit a migration that has been merged.** Write a new one.
- **Expand → migrate → contract**, across separate deploys:
  1. add the new column/table (nullable, defaulted, no constraint),
  2. backfill and dual-write,
  3. only then drop or tighten.
- No destructive statement (`DROP`, `TRUNCATE`, `ALTER ... DROP COLUMN`, type
  narrowing) in the same migration as an additive one.
- Adding a `NOT NULL` column to a populated table requires a default or a
  backfill step — otherwise it locks or fails.
- Index creation on a large table must be concurrent/online where the engine
  supports it.
- Every migration has a **tested rollback**, or an explicit comment saying why it
  cannot be rolled back and what the recovery procedure is.
- Data migrations are batched and resumable; never one statement over the whole
  table.
- Parameterized statements only. No string interpolation, even here.

State the blast radius (rows touched, expected duration, locks taken) in the PR.
