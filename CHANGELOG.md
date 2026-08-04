# Changelog

All notable changes to this project are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Graphical rendering (completes Phases 2, 9, 12; advances 11, 14).** The
  overlay is now a real `eframe`/`egui` GPU renderer: a transparent, borderless,
  always-on-top, mouse-pass-through window drawing themed CPU/RAM/swap/disk
  gauges that **ease** toward each reading (Phase 9 `anim` applied), anchored to
  the configured corner, toggled with `Ctrl+Alt+H` (`halo overlay`). Adds a
  graphical settings window with live preview that writes `config.toml`
  (`halo settings`, feature `gui`). Adds a real `GitPlugin` (reads `.git/HEAD`)
  and wires the plugin registry into widget resolution so `widgets = ["cpu",
  "git"]` works. Feature-gated (`overlay`, `gui`); the default build stays
  windowing-free. Not visually verified in this headless environment — compiles
  and lints clean on macOS and, via CI, on Linux. GPU-metric sampling (the `gpu`
  widget) remains a placeholder.

### Changed

- Slimmed the README to launch + configuration only; moved vision, stack,
  architecture, roadmap and development docs to [`docs/OVERVIEW.md`](docs/OVERVIEW.md).

### Fixed

- **Overlay ignored its `position` on Wayland** (landed centred on Ubuntu/GNOME
  while working on macOS/X11). Wayland does not let clients position their own
  top-level windows, so `OuterPosition` was a no-op. Halo now forces the X11
  (`XWayland`) backend on a Wayland session, where corner anchoring works. The
  first attempt set `WINIT_UNIX_BACKEND=x11`, but winit 0.30 removed that
  variable, so it silently did nothing; the backend is now forced through
  eframe's `event_loop_builder` hook (`EventLoopBuilderExtX11::with_x11`). Run
  without `DISPLAY` (`env -u DISPLAY halo`) to force native Wayland.


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
- **Phase 11** — plugin system (`halo-ui::plugin`): a `Plugin` trait contributes
  widgets and a `PluginRegistry` resolves ids from plugins first then built-ins,
  so extensions add widgets without touching the core. Includes an
  `ExamplePlugin` template. External shared-library plugins remain future work.
- **Phase 12** — configuration write-back: `Config::to_toml`, `save` and
  `save_default` persist settings so nothing is hand-edited; exposed via
  `halo init`. Opacity is now `f64` for clean TOML round-tripping. The graphical
  settings window (egui, live preview) builds on these APIs and is deferred
  (needs a desktop session).
- **Phase 13** — per-sensor scheduler in `halo-core`: `SensorIntervals` gives
  each sensor its own cadence (CPU 250 ms, memory 2 s, disk 5 s, network 1 s,
  temperature 2 s). `Monitor` refreshes only what is due and returns a cached
  `Sample`, so sampling at the display rate no longer re-reads every sensor —
  fewer wakeups, lower CPU. `Monitor::with_intervals` allows custom cadences.
- **Phase 14** — roadmap status matrix in the README honestly tracking each
  phase (✅ done / 🟡 logic-done, GPU-render pending / ⏳ todo). All logic and the
  terminal HUD are complete and tested; reaching a true 1.0 requires the GPU
  render engine (visible overlay widgets, GPU metrics) and the settings GUI,
  which need a Linux graphical session to build and verify.

[Unreleased]: https://github.com/YohanGH/halo/commits/main
