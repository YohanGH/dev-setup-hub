# Contributing to Halo

Thanks for your interest in Halo — a lightweight, 100% Rust system HUD.
This guide covers the workflow and the local checks that mirror CI.

## Prerequisites

- A stable Rust toolchain via [rustup](https://rustup.rs). The pinned channel
  and components are declared in [`rust-toolchain.toml`](rust-toolchain.toml),
  so `rustup` installs the right ones automatically.
- On Linux you will eventually need the usual Wayland/X11 development headers
  for the overlay crate; the core, config and daemon crates build without them.

## Project layout

Halo is a Cargo workspace. Each concern lives in its own crate under
[`crates/`](crates/); see the **Architecture** section of the
[README](README.md) for how they fit together.

## Local checks

Run these before opening a pull request — they are exactly what CI enforces:

```bash
cargo fmt --all                              # format
cargo clippy --workspace --all-targets       # lint (warnings are errors in CI)
cargo test --workspace                       # tests
cargo deny check                             # supply-chain / licence audit
```

Run a single crate's tests, or a single test:

```bash
cargo test -p halo-core
cargo test -p halo-config partial_config_falls_back_to_defaults
```

## Commit & PR conventions

- Keep commits focused; write imperative subject lines
  (`Add network sampling to halo-core`).
- Reference the roadmap phase your change advances in the PR description.
- Update the README, docs and [`CHANGELOG.md`](CHANGELOG.md) when behaviour
  changes.
- New crates must set `[lints] workspace = true` so shared lint policy applies.

## Coding standards

- `unsafe` code is denied workspace-wide; if an exception is unavoidable, isolate
  it, document the invariant, and call it out in review.
- Prefer adding logic to the right layer: monitoring in `halo-core`, schema in
  `halo-config`, rendering in `halo-ui`, orchestration in `halo-daemon`.
- Keep the core dependency-light: reach for direct `/proc` / `/sys` reads over a
  new dependency when it yields a real gain.

By contributing you agree that your work is licensed under the project's
[MIT License](LICENSE).
