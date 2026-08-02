---
name: cross-platform-script
description: Write or review a TypeScript tooling script that must run identically on Windows, macOS, and Linux. Use when adding anything under scripts/, a build/release helper, or a CLI task.
---

# Writing a cross-platform TS tooling script

The team runs Windows, macOS, and Linux, and scripts must behave identically on
all three while staying backward-compatible with the Node version everyone uses.
Follow this when authoring or reviewing a `scripts/*.ts` file.

## Checklist

1. **Paths** — build every path with `path.join` / `path.resolve`. Never
   concatenate with `/` or `\`. Use `path.sep` only when you truly need the
   separator.
2. **Filesystem** — use `fs.promises`: `rm(p, { recursive: true, force: true })`,
   `cp`, `mkdir(p, { recursive: true })`. Do **not** shell out to `rm`, `cp`,
   `mkdir`, `del`, or `xcopy`.
3. **Spawning processes** — if you must run a binary, use `execa` or
   `child_process.spawn(cmd, argsArray, { shell: false })`. Never build a single
   shell string (quoting and `&&` differ per OS). Resolve tool paths, don't assume
   they're on `PATH`.
4. **Environment** — `os.homedir()`, `os.tmpdir()`, `process.platform`,
   `process.env`. Never read `$HOME`/`%USERPROFILE%` directly.
5. **Line endings & encoding** — write `\n` explicitly; pass `'utf8'`. Don't rely
   on the platform default.
6. **Package manager** — during the npm→yarn migration, detect the lockfile before
   invoking a manager (see `.claude/rules/package-manager.md`); don't hardcode `yarn`
   or `npm`.
7. **Backward compatibility** — stick to Node APIs available in the team's pinned
   `engines.node`. If you need a newer API, flag it rather than silently raising the
   floor.
8. **Exit behavior** — set a non-zero exit code on failure (`process.exitCode = 1`);
   don't `throw` past the top level unhandled.

## Verify

- Reason through how each filesystem/spawn call behaves on Windows specifically —
  that's where POSIX assumptions break.
- Run `yarn typecheck`. If a quick smoke test is cheap, run the script once.
- Add or update a smoke test per `.claude/rules/testing.md` (cross-platform scripts
  are on the "worth testing" list).
