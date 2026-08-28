---
description: Shared library conventions — loaded when touching packages/shared
paths:
  - "packages/shared/**"
  - "packages/*/src/**"
---

# Shared packages (`packages/*`)

Everything here is consumed by more than one app, so a change is a **contract
change**.

- **Breaking a shared export breaks every consumer.** Before changing a
  signature, find the call sites and update them in the same change — or add a
  new export and deprecate the old one.
- Public surface is explicit: only what the package's entry point exports is
  public. Deep imports into a package's internals are a defect on the caller.
- No app-specific logic here. If only one app needs it, it belongs in that app.
- No framework or transport dependencies (no HTTP client, no UI library) — these
  packages must be importable from anywhere, including scripts and tests.
- Pure and deterministic where possible: no ambient clock, no `process.env`
  reads, no I/O at module load.
- Every exported symbol has a doc comment stating what it guarantees, not what
  it does.
- Shared types are the single source of truth for the API contract; they are
  generated from the schema, not hand-edited.
