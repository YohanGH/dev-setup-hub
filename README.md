# Unified Dev Configs

**One repo to hold all my dev environment configs — past, present, evolving.**  

## Why
- Centralise historical configs into a single evolving environment
- Make onboarding/rebuilds deterministic (fresh laptop = 30 min)
- Document opinions and trade-offs as practices mature

## Quickstart

Works the same on macOS and Debian/Ubuntu — the OS is detected, not chosen.

```bash
git clone https://github.com/YohanGH/dev-setup-hub.git
cd dev-setup-hub
./install.sh
```

Each step asks before it runs. To see them without installing anything:

```bash
./install.sh --list
```

Every step is also runnable on its own, in any order:

```bash
./install/10-shell.sh
```

| Option | Effect |
|---|---|
| `--yes` | run every step without asking |
| `--list` | list the steps, install nothing |
| `--only 10` | run only the step whose name starts with `10` |

Browsers are deliberately **not** installed, and neither is Cursor, which
manages its own updates — see [docs/MANUAL.md](docs/MANUAL.md) for those and
for the Debian GUI apps.

## What’s inside

Three axes, kept separate on purpose:

- **/profiles/**: *what* to install — package lists, one per OS
- **/install/**: *how* — one file per step, OS-agnostic
- **/config/**: *the content* — your actual config, one directory per tool
  - **zsh/**, **editor/**, **header/**, **obsidian/**
- **/lib/**: shared shell helpers — `ui.sh`, `os.sh`, `fs.sh`, `profile.sh`.
  `os.sh` is the only place that knows macOS from Debian.

- **external.conf**: repos that stay in their own GitHub project and get
  cloned at install time — never copied in here, where they would drift

Still being folded in:

- **/vim/**: moves under `config/` once its split into fragments is finished
- **/debian/**: legacy scripts, kept as a working fallback until the new
  install path is validated on a real Debian box

> A restructuring is in progress — see [REFACTOR_PLAN.md](REFACTOR_PLAN.md).