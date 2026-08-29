# Security Policy

## Scope

This repository ships configuration files and shell scripts, not production
code. The risk it carries is therefore mostly one of **supply chain and
execution**: the install scripts fetch third-party code and run it on your
machine.

## Reporting a vulnerability

If you find a security issue — an exposed secret, an unsafe script, a
compromised upstream — please do **not** open a public issue with the details.

- Open a [private security advisory](https://github.com/YohanGH/dev-setup-hub/security/advisories/new)
  on GitHub, or
- email <YohanGH@proton.me>.

Expect an acknowledgement within 72 hours, and a fix or mitigation within
14 days.

## What this repository fetches and runs

Being explicit about it is part of the policy. `install.sh` downloads and
executes code from:

| Source | Step | What it does |
|---|---|---|
| Homebrew / apt | `00-packages.sh` | installs packages, `sudo` on Debian |
| `ohmyzsh/ohmyzsh` | `10-shell.sh` | install script piped to `sh` |
| `romkatv/powerlevel10k` | `10-shell.sh` | shallow `git clone` |
| `zsh-users/*` | `10-shell.sh` | shallow `git clone` |
| `nvm-sh/nvm` | `15-node.sh` | install script piped to `bash` |
| npm registry | `15-node.sh` | `npm install -g prettier` |
| repos in `external.conf` | `50-external.sh` | `git clone`, optional build |
| VSCode / Open VSX | `30-editor.sh` | extension install |

Everything here is pinned to a **branch, not a commit**, apart from nvm which
is pinned to a tag. Upstream can therefore change under you between two runs.
Read `install/*.sh` before the first run if that matters to you.

## Hardening guidelines

- Never commit secrets. `.gitignore` already excludes `.env`, `*.key` and
  `*.pem`; keep real secrets in a password manager, not in this repository.
- Machine-specific values belong in `~/.zsh_local`, which is never versioned.
- Review third-party install scripts before running them. The table above
  tells you where to look.
- Prefer least privilege for any token used locally.

## Backups before anything is overwritten

No install step destroys an existing file. `lib/fs.sh` archives whatever it is
about to replace as `<file>.bak.<timestamp>`, so a bad run can be undone by
hand.
