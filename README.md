# dev-setup-hub

**One repo holding every dev environment config, for two machines: macOS and
Debian/Ubuntu.**

The OS is detected, never chosen. The same command sets up either machine, and
the same config file serves both.

## Why

- Centralise configs that used to live in five separate repos
- Make a rebuild deterministic — fresh laptop to working setup in one pass
- Keep one source of truth per tool, so fixing a config fixes it everywhere

---

## Quickstart

```bash
git clone https://github.com/YohanGH/dev-setup-hub.git
cd dev-setup-hub
./install.sh
```

Every step asks before it runs. Nothing is overwritten without being archived
first as `<file>.bak.<timestamp>`.

| Option | Effect |
|---|---|
| `--list`, `-l` | list the steps, install nothing |
| `--yes`, `-y` | run everything without asking |
| `--only <n>` | run only the step whose name starts with `<n>` |
| `--help`, `-h` | usage |

**On macOS, install Homebrew first** — its installer needs a confirmation and
the Xcode command line tools, so this repo points at it rather than running it
for you:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

---

## Step by step

Every step is a standalone script. Run them in any order, re-run them freely —
they are idempotent, and a second run reports what is already in place instead
of redoing it.

See what exists first:

```bash
./install.sh --list
```

**1 — System packages.** Reads `profiles/`, installs through brew or apt
depending on the machine. On macOS it also installs the GUI apps listed in
`profiles/macos-cask.list`.

```bash
./install/00-packages.sh
```

**2 — Shell.** oh-my-zsh, powerlevel10k, the two zsh plugins, then links
`~/.zshrc` and `~/.zsh_aliases` to `config/zsh/`. Editing the repo is enough
afterwards — no reinstall.

```bash
./install/10-shell.sh
```

**3 — Node.** nvm, the current Node LTS, prettier.

```bash
./install/15-node.sh
```

**4 — Vim header.** Links the 42-style `stdheader.vim` into `~/.vim/plugin/`.
Insert a header with `F1` or `:Stdheader`.

```bash
./install/20-header.sh
```

**5 — Editors.** Copies the same `settings.json`, `keybindings.json` and
extension list into **both** VSCode and VSCodium.

```bash
./install/30-editor.sh
./install/30-editor.sh --no-extensions   # config only
```

**6 — Obsidian.** Needs the path to your vault, since that is per-machine.
Deploys the settings only. Community plugins are not versioned here and
Obsidian does not reinstall them by itself — see
[config/obsidian/plugins.md](config/obsidian/plugins.md) for the inventory.

```bash
./install/40-obsidian.sh ~/path/to/vault
```

**7 — External repos.** Fetches the repos declared in `external.conf` instead
of vendoring them here: a release binary when one matches the platform, else
the release's source (pinned to that tag, not the moving default branch), else
a plain clone if the repo has never published a release. `halo` is Linux-only
and off by default — even as a binary, a HUD overlay isn't an everyday dev
tool.

```bash
./install/50-external.sh
./install/50-external.sh --with halo
```

**8 — Check.** Read-only. Reports what is installed, what is linked, and what
is left for you to do by hand.

```bash
./install/99-summary.sh
```

---

## What’s inside

Three axes, kept separate on purpose — see
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

| Path | Role |
|---|---|
| `profiles/` | **what** to install — package lists, one per OS |
| `install/` | **how** — one file per step, never branches on the OS |
| `config/` | **the content** — `zsh/`, `editor/`, `header/`, `obsidian/` |
| `lib/` | shared helpers — `ui.sh`, `os.sh`, `fs.sh`, `profile.sh` |
| `external.conf` | repos that stay in their own project — fetched from their latest release, cloned only if they have none |

Adding a step means dropping a file in `install/`: it registers itself.

Still being folded in:

- `vim/` — moves under `config/` once its split into fragments is finished
- `debian/` — legacy scripts, kept as a working fallback until the new path is
  validated on a real Debian box

## Not automated

Browsers and Cursor are deliberately left out, and the Debian GUI apps each
need their own third-party repo. All of it, with the reasoning and the manual
commands, is in [docs/MANUAL.md](docs/MANUAL.md).

## Documentation

| | |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | the three axes, where to add what *(FR)* |
| [docs/MANUAL.md](docs/MANUAL.md) | what stays manual, and why *(FR)* |
| [CONTRIBUTING.md](CONTRIBUTING.md) | conventions, shell style, adding a step |
| [SECURITY.md](SECURITY.md) | what this repo downloads and runs |
| [REFACTOR_PLAN.md](REFACTOR_PLAN.md) | the ongoing restructuring *(FR)* |

## License

[MIT](LICENSE).
