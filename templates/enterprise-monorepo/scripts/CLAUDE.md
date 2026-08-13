# scripts/ — repo tooling

<!-- Loads on demand when Claude reads a file here. -->

Build, release, migration and maintenance scripts shared by the whole repo.

## Rules

- **Cross-platform by default.** Teammates and CI run different operating
  systems — see the `cross-platform-script` skill before writing anything here.
- Every script is **idempotent** and safe to run twice.
- Every script exits non-zero on failure. A script that fails silently gets
  wired into CI and trusted.
- No secrets, no credentials, no `curl | sh`.
- A script that only one package needs belongs in that package, not here.

## Commands

- Run: `<RUN_SCRIPT_CMD> scripts/<name>`
- Typecheck/lint them like any other source — they are code.
