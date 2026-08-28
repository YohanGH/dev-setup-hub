# Code style

> Formatting is **enforced by `<FORMATTER>`** and linting by `<LINTER>`. Nothing
> in this file repeats what those tools already guarantee. What follows is the
> judgement they can't encode.

## Naming

- Names state intent, not type: `pendingInvoices`, not `invoiceArray`.
- Booleans read as predicates: `isExpired`, `hasAccess`, `canRetry`.
- Functions are verb phrases; modules and types are noun phrases.
- No abbreviations except the ones already in the domain glossary
  (`<GLOSSARY_PATH>`). `qty` is fine if the business says "qty"; `usrMgr` is not.
- Avoid `utils`/`helpers`/`common` as a destination. If a function has no better
  home, its home is probably next to its only caller.

## File and module layout

- One exported concept per file; the file is named after it.
- Import order: standard library → third party → workspace packages → relative.
  Enforced by `<LINTER>`; don't hand-sort.
- No deep relative imports across package boundaries (`../../../other-package`).
  Cross-package access goes through the package's public entry point.
- Shared types live in `packages/shared` and are imported, never redeclared.

## Functions

- A function does one thing at one level of abstraction.
- Prefer early returns over nested conditionals.
- More than ~3 positional parameters → take an options object.
- Pure where it can be pure: push I/O to the edges so the core stays testable.

## Error handling

- **Never swallow an error.** No empty `catch`. If it is genuinely ignorable,
  a comment must say why.
- Throw typed/domain errors, not bare strings.
- Add context when rethrowing: `throw new StorageError("write invoice", { cause })`.
- Validate at the boundary (HTTP handler, queue consumer, CLI entry). Inside the
  boundary, assume validated data and don't re-check defensively.
- User-facing messages never leak internals — no stack traces, SQL, or paths.

## Comments

- Comment **why**, never **what**. A comment restating the code is a defect.
- Every non-obvious workaround gets a comment with the reason and, if it exists,
  the ticket or upstream issue link.
- `TODO` is only acceptable with a ticket reference: `// TODO(PROJ-1234): ...`.
  Untracked TODOs are rejected in review.

## Dependencies

- Adding a dependency is a decision, not a detail: justify it in the PR body.
- Prefer the standard library and what's already in the lockfile.
- No dependency for something under ~30 lines of obvious code.
- Never mix package managers inside one package (one lockfile, exactly).

## Things that get rejected in review

- Commented-out code (git remembers it).
- Reformatting unrelated lines inside a behaviour change — it hides the real diff.
- New `any` / untyped escapes without a comment justifying them.
- Copy-pasted blocks that differ by one constant.
- Changes to generated files by hand (regenerate instead).
