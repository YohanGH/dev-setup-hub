# Project — cross-platform TypeScript product

<!-- Keep this file lean (< ~200 lines). Stack-specific detail lives in
     .claude/rules/ and loads only when relevant. See docs/rules-and-skills.md. -->

Monorepo shipping a Vue/Quasar web app, a NestJS REST API, and an Electron
desktop build — all TypeScript, on Windows / macOS / Linux.

## Layout

- `apps/web` — Vue 3 + Quasar (browser).
- `apps/desktop` — Electron (Quasar `electron` mode), packaged for Win/mac/Linux.
- `apps/api` — NestJS REST API.
- `packages/*` — shared TS libraries (types, utils) consumed by the apps.
- `scripts/*` — TS tooling scripts; must run on all three OSes.

## Commands

> We're **migrating npm → yarn** and it isn't finished. Use the package manager
> that matches the lockfile in the package you're in — see
> `.claude/rules/package-manager.md`. The commands below assume yarn.

- Install: `yarn install`
- Dev (per app): `yarn workspace @app/web dev` · `@app/api start:dev` · `@app/desktop dev`
- Typecheck: `yarn typecheck` (must pass before any commit)
- Lint / format: `yarn lint` · `yarn format`
- Test: `yarn test` (see `.claude/rules/testing.md` for what's worth testing)
- Build all: `yarn build`

## Always-true conventions

- **TypeScript only**, `strict` on. No new plain-`.js` source files.
- **Cross-platform by default**: never assume a shell, a path separator, or an OS.
  Use Node's `path`/`os`/`fs` APIs in scripts, not `bash`-isms.
- **REST**: DTOs are validated (`class-validator`); errors use the shared error shape.
- **Don't mix package managers** in one package (never both `package-lock.json`
  and `yarn.lock`).
- Conventional Commits. Small, reviewed diffs. Don't push or open PRs unless asked.

## Where to look

- Shared types live in `packages/` — reuse them, don't redeclare.
- Path-scoped rules in `.claude/rules/` carry the per-area detail (Vue, NestJS,
  Electron, TS scripts, testing).
