# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What Halo is

Halo is a lightweight, 100% Rust system HUD: a transparent, click-through,
always-on-top overlay that displays system metrics on Linux (Wayland & X11).
It is pre-alpha — the workspace is scaffolded and most roadmap phases are not yet
implemented. See [README.md](README.md) for the full vision and the 14-phase
roadmap; the roadmap phase is the unit of work for PRs and issues.

## Commands

```bash
cargo run -p halo-cli                      # build & run the HUD (defaults)
cargo run -p halo-cli -- --config examples/config.toml
cargo run -p halo-cli -- config            # print effective config, don't launch

cargo build --workspace --all-targets
cargo test --workspace                     # all tests
cargo test -p halo-core                    # one crate
cargo test -p halo-config partial_config_falls_back_to_defaults  # one test

cargo fmt --all                            # format (rustfmt.toml)
cargo clippy --workspace --all-targets     # lint — CI runs with -D warnings
cargo deny check                           # supply-chain / licence audit (deny.toml)

cargo install --path crates/halo-cli       # install the `halo` binary
```

Note: the Rust toolchain is not assumed to be installed in every environment;
`rust-toolchain.toml` pins stable + rustfmt + clippy for those that have rustup.

## Architecture

Cargo workspace; each crate is one responsibility and dependencies flow one way.
Put new code in the layer that owns the concern rather than reaching across:

- **halo-core** — monitoring model (`Sample`) and the `Monitor` sampler. No UI
  or config deps. The `sysinfo` backend is intended to be swapped for direct
  `/proc` and `/sys` reads where that pays off.
- **halo-config** — the `Config` schema and TOML (de)serialisation. `#[serde(default)]`
  means partial configs fall back to defaults; keep defaults matching the README
  and `examples/config.toml`.
- **halo-themes** — `Theme` / `Color` visual definitions. Widgets read a theme;
  they never hard-code colours.
- **halo-ui** — the `Overlay` trait and `TextOverlay` (headless, dependency-free,
  used for early bring-up and tests). The GPU backend (egui/Slint over wgpu) lands
  behind this trait so the rest of Halo never depends on a toolkit directly.
- **halo-daemon** — `run()` ties core + config + ui into the async Tokio loop
  (sample on interval → render → clean Ctrl-C shutdown). Front-ends reuse this.
- **halo-cli** — the `halo` binary (clap). Thin: parse args, load config, call
  `halo_daemon::run`.

Shared dependency versions and lint policy live in the root `Cargo.toml` under
`[workspace.dependencies]` and `[workspace.lints]`. New crates must set
`[lints] workspace = true`.

## Conventions

- `unsafe_code` is `warn`/denied workspace-wide — isolate and justify any exception.
- CI treats warnings as errors (fmt, clippy, tests on stable + MSRV 1.75; a
  weekly `cargo deny` audit). Run fmt + clippy + test before proposing changes.
- `release` profile is tuned for a small background binary (thin LTO, strip,
  `panic = "abort"`); avoid relying on unwinding in library code.
