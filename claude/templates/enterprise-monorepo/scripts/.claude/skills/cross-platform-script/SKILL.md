---
name: cross-platform-script
description: Write or review a tooling script that must run identically on Windows, macOS and Linux. Use when adding anything under scripts/, a build or release helper, a CI task, or a CLI utility.
when_to_use: Triggered while working on files under scripts/, or when a script needs to work on a teammate's different OS.
allowed-tools: Read Grep Glob Edit Write Bash
---

# Cross-platform tooling scripts

Loads only while working in `scripts/`. The team runs different operating
systems; a script that works on the author's machine and nowhere else is a
script that gets rewritten by whoever is blocked by it.

Windows is where POSIX assumptions break. Reason about it explicitly for every
filesystem and process call — not at the end, but as you write each one.

## Checklist

1. **Paths** — build every path with the platform's path API (`path.join` /
   `path.resolve`, `os.path.join`, `filepath.Join`). Never concatenate with `/`
   or `\`. A hardcoded separator is the single most common failure here.
2. **Filesystem** — use the language's filesystem API, not shelled-out commands.
   `rm`, `cp`, `mkdir`, `del` and `xcopy` differ in name, flags and behaviour
   across platforms; the library call does not.
3. **Spawning processes** — pass an **argument array**, never a single shell
   string. Quoting rules, `&&`, and variable expansion all differ per OS, and a
   string built from a variable is also a command-injection surface. Resolve
   tool paths rather than assuming `PATH`.
4. **Environment** — use the platform-neutral accessors (`os.homedir()`,
   `os.tmpdir()`, `process.platform`). Never read `$HOME` or `%USERPROFILE%`
   directly.
5. **Line endings and encoding** — write `\n` explicitly and pass `utf8`. Do not
   rely on the platform default; it will differ, and the diff noise will be
   blamed on someone else.
6. **Package manager** — detect the lockfile in the package you are operating on
   rather than hardcoding one. `.claude/scripts/lib/common.sh` has
   `cc_detect_pm` for exactly this. A repo mid-migration has both kinds.
7. **Backward compatibility** — stay within the runtime version the team pins.
   If you need a newer API, say so and let someone decide — do not silently
   raise the floor for everyone.
8. **Exit behaviour** — a non-zero exit code on failure, always. A script that
   fails silently and returns `0` will be wired into CI and trusted.
9. **Idempotence** — safe to run twice. The second run is the one that happens
   during an incident.

## Shell scripts specifically

If it is a `.sh`, it will not run on Windows outside WSL or Git Bash. That is a
legitimate choice, but make it a stated one: say so in the script header and in
the README, or write it in the repo's language instead.

When you do write shell:

- Quote every variable expansion. A path with a space is not an edge case.
- `set -u` to catch typos in variable names. Add `-e`/`-o pipefail` deliberately
  — in a hook they can turn a survivable error into a wedged session.
- Test for a command before using it, and degrade rather than crash.

## Verify before committing

- Walk through each filesystem and spawn call and ask what it does on Windows.
- Run the repo's typecheck/lint for the script's language.
- Run the script once. A tooling script that has never been executed is a draft.
- Add a smoke test if the script is load-bearing for CI or releases — these are
  on the "worth testing" list in `.claude/conventions/testing.md`.
