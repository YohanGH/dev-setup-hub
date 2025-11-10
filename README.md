# Unified Dev Configs

**One repo to hold all my dev environment configs — past, present, evolving.**  

## Why
- Centralise historical configs into a single evolving environment
- Make onboarding/rebuilds deterministic (fresh laptop = 30 min)
- Document opinions and trade-offs as practices mature

## What’s inside
- **/profiles/**: opinionated bundles (e.g., `minimal`, `fullstack`, `data-science`)
- **/vscode/**: `settings.json`, `keybindings.json`, recommended extensions list
- **/shell/**: zsh/bash config, aliases, prompt, env exports
- **/git/**: `.gitconfig`, sample hooks (pre-commit, commit-msg)
- **/containers/**: devcontainers, Docker-based dev setups
- **/scripts/**: bootstrap/install scripts (macOS/Linux/WSL)

## Quickstart
```bash
# choose a profile, then bootstrap
./scripts/bootstrap.sh profiles/fullstack
# Unified Dev Configs

**One repo to hold all my dev environment configs — past, present, evolving.**  
Exploratory prototypes built in hackathons and daily engineering work, consolidated into a single, reproducible setup.

## Why
- Centralise historical configs into a single evolving environment
- Make onboarding/rebuilds deterministic (fresh laptop = 30 min)
- Document opinions and trade-offs as practices mature

## What’s inside
- **/profiles/**: opinionated bundles (e.g., `minimal`, `fullstack`, `data-science`)
- **/vscode/**: `settings.json`, `keybindings.json`, recommended extensions list
- **/shell/**: zsh/bash config, aliases, prompt, env exports
- **/git/**: `.gitconfig`, sample hooks (pre-commit, commit-msg)
- **/containers/**: devcontainers, Docker-based dev setups
- **/scripts/**: bootstrap/install scripts (macOS/Linux/WSL)

## Quickstart
```bash
# choose a profile, then bootstrap
./scripts/bootstrap.sh profiles/fullstack

