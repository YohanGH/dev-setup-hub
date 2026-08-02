---
paths:
  - "**/*.ts"
  - "scripts/**/*"
---

# TypeScript & cross-platform scripts

Loads whenever Claude touches a `.ts` file or anything under `scripts/`.

## TypeScript

- `strict` is on. No `any` without a `// reason:` comment; prefer `unknown` + narrowing.
- Reuse shared types from `packages/` — don't redeclare domain types per app.
- No new plain-`.js` source. Type config files too (`*.config.ts`).
- Public functions get explicit return types.

## Cross-platform tooling scripts (`scripts/*.ts`)

The team runs Windows, macOS, and Linux. Scripts must run identically on all three.

- **Paths**: use `path.join` / `path.resolve`; never hardcode `/` or `\`.
- **No shell-isms**: avoid `rm -rf`, `cp`, `&&`-chains in `child_process`. Use
  `fs.promises` (`rm`, `cp`, `mkdir { recursive: true }`) and Node APIs instead.
- **Env & home**: `os.homedir()`, `os.tmpdir()`, `process.platform` — not `$HOME`.
- **Line endings**: write `\n`; don't depend on the platform default.
- **Executables**: prefer calling Node/TS directly over OS binaries; if you must
  spawn, pass args as an array (no shell string), and set `shell: false`.

## Backward compatibility

- Keep `tsconfig` `target`/`lib` and `engines.node` aligned with what the whole
  team runs — don't bump them casually; call it out if a change requires it.
- New tooling should degrade gracefully if an optional dep is missing.
