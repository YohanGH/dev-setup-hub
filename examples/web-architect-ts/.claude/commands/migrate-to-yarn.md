---
description: Migrate one package from npm to yarn (per the mixed-state migration)
argument-hint: <path-to-package> (defaults to the current package)
---

Migrate the package at **$ARGUMENTS** (or the current one if empty) from npm to
yarn, following `.claude/rules/package-manager.md`. Work carefully — the repo is
mid-migration.

Steps:

1. **Check state.** Confirm the package has `package-lock.json` and no `yarn.lock`.
   If both exist, **stop** and tell me — that's a bad-merge bug, don't guess.
2. Record the current dependency versions (read `package-lock.json`) so we can
   verify nothing drifts.
3. Remove `package-lock.json`; run `yarn install` at the repo root so the package
   is resolved through **yarn workspaces**.
4. Verify a clean, reproducible install: `yarn install --immutable` must pass.
5. Run `yarn typecheck` and the package's tests.
6. Diff the resolved versions against step 2; call out any major bumps rather than
   accepting them silently.
7. Stage the removed `package-lock.json` and the new/updated `yarn.lock` **together**
   and show me the diff.

Report what changed and what you verified. Don't commit or push unless I confirm.
