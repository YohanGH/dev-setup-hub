# packages/shared — cross-package contracts

<!-- Loads on demand when Claude reads a file here. Small on purpose: this
     package's rule is short and absolute. -->

Types and pure utilities imported by `apps/api` and `apps/web`.

## The rule that governs everything here

**A change here is a contract change.** Both apps compile against this package,
so a signature change breaks them in the same commit — or worse, at runtime if
the data was already serialized with the old shape.

Before changing an exported symbol:

1. Find every call site across the repo (`@impact-scout` if it spans packages).
2. Either update them all in the same change, or add a new export and deprecate
   the old one.
3. If persisted data or an in-flight message uses the old shape, the new code
   must still read it.

## Constraints

- No framework, transport, or UI dependency. This package must be importable
  from a script, a test, or either app.
- No I/O, no `process.env`, no ambient clock at module load. Pure and
  deterministic.
- Only the entry point is public. A consumer reaching into internals is a defect
  on the consumer, but a deep path that works is an invitation — keep internals
  unexported.
- API types here are generated from the API schemas. Edit the schema, regenerate;
  do not hand-edit the generated file.

## Commands

- Test: `<TEST_CMD>` · Build: `<BUILD_CMD>` — from `packages/shared/`.
