# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Cargo workspace scaffold with six crates: `halo-core`, `halo-config`,
  `halo-ui`, `halo-daemon`, `halo-themes`, `halo-cli`.
- `halo` binary that loads configuration and runs the sampling loop
  (prints "Hello Halo" on start — Roadmap Phase 0/1).
- Headless `TextOverlay` reporting CPU and RAM each tick.
- MIT license, security policy, contribution guide and code of conduct.
- CI (fmt, clippy, test) and a weekly `cargo deny` security audit.
- **Phase 1** — full monitoring model in `halo-core` (`Sample` with CPU, RAM,
  swap, disk, network rates and temperature) backed by `sysinfo`; timed run
  loop printing `CPU/RAM/DISK/TEMP` each tick with clean Ctrl-C shutdown and
  structured `tracing` logs. Byte/rate/temperature formatting helpers in
  `halo-ui::format`; `Theme::by_name` lookup.
- **Phase 2** — windowed overlay backend (`halo-ui::overlay`, feature `overlay`):
  a transparent, borderless, always-on-top, click-through `winit` window anchored
  to the configured corner, with a global hotkey (`Ctrl+Alt+H`) to toggle
  visibility and `Esc` to quit. Exposed as `halo overlay`. Off by default so the
  terminal HUD and CI stay windowing-free.
- **Phase 3** — HUD line now reports swap usage and network throughput
  (↓rx ↑tx) beside CPU/RAM/disk/temperature.
- **Phase 4** — `config.toml` auto-discovery: `Config::load_default()` reads
  `$XDG_CONFIG_HOME/halo/config.toml` (or `~/.config/halo/config.toml`) at
  startup, falling back to defaults when absent. Loaded values are clamped to
  safe ranges (`Config::normalized`).
- **Phase 7** — widget architecture (`halo-ui::widget`): a `Widget` trait with
  independent CPU, RAM, swap, disk, network, temperature, GPU (placeholder) and
  clock widgets, a `by_id` registry and `render_line` composer. The HUD line and
  `TextOverlay` are now built from an ordered widget set.
- **Phase 8** — seven built-in themes (minimal, cyberpunk, terminal, glass,
  nord, oled, monochrome) with `Color::rgba`, `themes::builtins()` and
  `themes::names()`.
- **Phase 9** — animation maths (`halo-ui::anim`): `lerp`, an `Easing` curve
  (linear / ease-out / ease-in-out) and a framerate-independent `Smoothed`
  exponential value so readings transition without abrupt jumps. Applied
  visually once the GPU renderer lands.
- **Phase 10** — customisation: optional `widgets` list in `config.toml` selects,
  orders, enables and disables widgets by id; `None` keeps the default set. The
  overlay honours it. Position/theme/opacity/font were already configurable.

[Unreleased]: https://github.com/YohanGH/halo/commits/main
