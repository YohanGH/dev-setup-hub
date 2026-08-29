# Contributing

This repository is a centralised, opinionated set of dev configs. It targets
two machines — macOS and Debian/Ubuntu — from a single source.

## Where things go

Three axes are kept separate on purpose. Before adding anything, decide which
one it belongs to:

| You want to… | Edit |
|---|---|
| install a new package | `profiles/*.list` |
| add an install step | a new `install/NN-name.sh` |
| change a tool's config | `config/<tool>/` |
| share logic between steps | `lib/` |
| pull in a whole external repo | `external.conf` |

The rule that keeps this working: **install steps never test the OS.** They
call `pkg_install` and let `lib/os.sh` resolve brew or apt. If you find
yourself writing `if macOS` in `install/`, the difference belongs in a profile
list or in `lib/os.sh` instead.

`docs/ARCHITECTURE.md` explains the layout in more detail.

## Adding an install step

Drop a file in `install/`. It registers itself — `install.sh` discovers steps
by sorting the directory and reads each description from an `# @desc:` line.
Nothing else to wire up.

A step must:

- start with `set -euo pipefail`;
- source what it needs from `lib/` using a path derived from its own location,
  so it runs from any working directory;
- stay runnable on its own, not only through `install.sh`;
- be idempotent — a second run reports "already present" rather than
  redoing the work;
- never overwrite a user file without `fs_backup` archiving it first.

## Shell style

- **Tabs** for indentation. This is what every script here already uses and
  what `shfmt` produces by default; `.editorconfig` sets it for `*.sh`.
- Bash, not POSIX sh — `lib/` uses arrays and `local`.
- CI runs `shellcheck` and `shfmt -d` over `lib/`, `install/` and
  `install.sh`. Run them locally before pushing if you have them.

Deliberately out of CI scope for now: `debian/scripts/`, kept as a working
fallback until the new install path is validated on a real Debian box.

## Proposing changes

1. Open an issue describing the change and the reasoning.
2. Branch off `main`.
3. Keep commits small and explain *why* in the message, not just what.
4. For scripts, say in the PR how you tested — and on which OS. A change that
   only ran on one of the two is fine, but say so.

## Secrets

Nothing secret is versioned here. Machine-specific values, tokens included, go
to `~/.zsh_local`, which no install step ever commits. See
[SECURITY.md](SECURITY.md).

## Code of Conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
