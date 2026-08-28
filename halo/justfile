# Halo task runner — run `just <task>` (https://github.com/casey/just).
# `just` is optional; every task is a plain cargo command you can run directly.

# Show available tasks.
default:
    @just --list

# Run the terminal HUD.
run:
    cargo run -p halo-cli

# Run the transparent overlay window (needs a desktop session).
overlay:
    cargo run -p halo-cli --features overlay -- overlay

# Print the effective configuration.
config:
    cargo run -p halo-cli -- config

# Install the `halo` binary into ~/.cargo/bin.
install:
    cargo install --path crates/halo-cli

# Build the whole workspace.
build:
    cargo build --workspace

# Format sources.
fmt:
    cargo fmt --all

# Lint with warnings treated as errors (matches CI).
lint:
    cargo clippy --workspace --all-targets -- -D warnings

# Run all tests.
test:
    cargo test --workspace

# Supply-chain / licence audit.
audit:
    cargo deny check

# Everything CI runs, in order.
ci: fmt lint test
