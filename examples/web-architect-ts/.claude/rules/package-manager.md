# Package manager — the npm → yarn migration

<!-- No `paths:` frontmatter on purpose: this is small and always relevant during
     the migration, so it loads every session. Delete this file once every repo
     is on yarn. -->

We are migrating everything to **yarn**, but it's **not finished** — the codebase
is in a mixed state. Get this right per package:

## Which one to use

1. Look at the **lockfile in the package you're working in**:
   - `yarn.lock` present → use **yarn** (`yarn`, `yarn add`, `yarn workspace …`).
   - only `package-lock.json` → this package isn't migrated yet → use **npm**
     (`npm ci`, `npm run …`). Don't silently switch it.
2. **Never create the other lockfile** in an already-committed package. Don't run
   `npm install` in a yarn package or vice-versa — it produces a second lockfile.
3. If both lockfiles exist, that's a bug from a bad merge → **stop and flag it**,
   don't guess.

## When asked to migrate a package

Use the `/migrate-to-yarn` command. In short: delete `package-lock.json`, run
`yarn import` (or a clean `yarn install`), verify `yarn install --immutable`,
run typecheck + tests, then commit the new `yarn.lock` and the removal together.

## Root / workspaces

- The repo uses **yarn workspaces**. Prefer `yarn workspace <name> <script>` over
  `cd`-ing into a package.
- Engines: keep `packageManager` in the root `package.json` pinned so everyone
  resolves the same yarn version (Corepack).
