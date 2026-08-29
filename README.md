# Unified Dev Configs

**One repo to hold all my dev environment configs — past, present, evolving.**  

## Why
- Centralise historical configs into a single evolving environment
- Make onboarding/rebuilds deterministic (fresh laptop = 30 min)
- Document opinions and trade-offs as practices mature

## What’s inside
- **/config/**: the configs themselves, one directory per tool, OS-agnostic
  - **zsh/**: zsh config, aliases, prompt, env exports
  - **editor/**: `settings.json`, `keybindings.json`, extensions list — VSCode and VSCodium
  - **header/**: 42-style file header plugin for Vim
  - **obsidian/**: Obsidian configuration
- **/lib/**: shared shell helpers (`ui.sh`, `os.sh`, `fs.sh`) used by the install steps
- **/vim/**: vim configuration — moves under `config/` once its split is finished
- **/setup/**, **/debian/**: legacy install scripts, replaced in phase 3
- **/claude/**, **/halo/**: vendored copies of standalone repos, fetched instead in phase 4

> A restructuring is in progress — see [REFACTOR_PLAN.md](REFACTOR_PLAN.md).