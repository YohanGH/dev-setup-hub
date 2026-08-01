//! GPU overlay backend (Roadmap Phases 2, 9, 14).
//!
//! Renders the HUD into a **transparent**, **borderless**, **always-on-top**,
//! **click-through** (mouse pass-through) window using `eframe`/`egui` on top of
//! a GPU backend. Percentages are drawn as gauges that **ease** toward each new
//! reading (Phase 9) using [`crate::anim::Smoothed`], themed via `halo-themes`
//! and anchored to the configured corner.
//!
//! Gated behind the `overlay` feature; requires a desktop session to run.
//!
//! ## Window positioning on Wayland
//!
//! Wayland deliberately does not let a normal client place its own top-level
//! window, so the configured corner is ignored and the compositor centres the
//! overlay (this is why the `position` setting appears to do nothing on GNOME
//! Wayland while working on X11 and macOS). A true corner anchor needs the
//! `wlr-layer-shell` protocol, which GNOME does not implement. As a pragmatic
//! fix, on a Wayland session Halo defaults to the **X11 (`XWayland`) backend**,
//! where `OuterPosition` is honoured. Override with `WINIT_UNIX_BACKEND=wayland`
//! to force native Wayland (accepting that the compositor controls position).

use std::error::Error;
use std::time::{Duration, Instant};

use eframe::egui::{self, Color32, RichText};
use global_hotkey::{
    hotkey::{Code, HotKey, Modifiers},
    GlobalHotKeyEvent, GlobalHotKeyManager, HotKeyState,
};
use halo_config::{Config, Position};
use halo_core::Monitor;
use halo_themes::{Color, Theme};

use crate::anim::Smoothed;
use crate::format;

/// Overlay window size in logical points.
const SIZE: [f32; 2] = [340.0, 156.0];
/// Margin from the screen edge, in points.
const MARGIN: f32 = 24.0;
/// Smoothing time constant (seconds) for the animated gauges.
const TAU: f32 = 0.18;

/// Launch the overlay window and run until the user quits.
///
/// The global hotkey `Ctrl+Alt+H` toggles visibility.
///
/// # Errors
/// Returns an error if the hotkey manager or the windowing backend fail.
pub fn run(config: Config) -> Result<(), Box<dyn Error>> {
    prefer_positionable_backend();

    let theme = Theme::by_name(&config.theme);

    let manager = GlobalHotKeyManager::new()?;
    let toggle = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::KeyH);
    manager.register(toggle)?;
    let toggle_id = toggle.id();

    let viewport = egui::ViewportBuilder::default()
        .with_title("Halo")
        .with_decorations(false)
        .with_transparent(true)
        .with_always_on_top()
        .with_mouse_passthrough(true)
        .with_resizable(false)
        .with_taskbar(false)
        .with_inner_size(SIZE);

    let options = eframe::NativeOptions {
        viewport,
        ..Default::default()
    };

    eframe::run_native(
        "halo",
        options,
        Box::new(move |_cc| Ok(Box::new(HaloApp::new(config, theme, manager, toggle_id)))),
    )?;
    Ok(())
}

/// On a Linux Wayland session, prefer the X11 (`XWayland`) backend so the overlay
/// can anchor to the configured corner. No-op on other platforms, and never
/// overrides an explicit `WINIT_UNIX_BACKEND`. See the module docs.
fn prefer_positionable_backend() {
    #[cfg(target_os = "linux")]
    {
        let backend_chosen = std::env::var_os("WINIT_UNIX_BACKEND").is_some();
        let on_wayland = std::env::var_os("WAYLAND_DISPLAY").is_some();
        if on_wayland && !backend_chosen {
            tracing::info!(
                target: "halo::overlay",
                "Wayland session detected; using the X11 (`XWayland`) backend so the \
                 overlay honours its `position`. Set WINIT_UNIX_BACKEND=wayland to force \
                 native Wayland (the compositor then controls the position)."
            );
            // Safe in edition 2021; set before any windowing/thread starts.
            std::env::set_var("WINIT_UNIX_BACKEND", "x11");
        }
    }
}

/// Convert a theme [`Color`] into an egui [`Color32`].
fn color32(color: Color) -> Color32 {
    Color32::from_rgba_unmultiplied(color.r, color.g, color.b, color.a)
}

struct HaloApp {
    config: Config,
    theme: Theme,
    monitor: Monitor,
    // Kept alive so the registered hotkey keeps firing.
    _hotkeys: GlobalHotKeyManager,
    toggle_id: u32,
    visible: bool,
    positioned: bool,
    last_frame: Instant,
    cpu: Smoothed,
    ram: Smoothed,
    swap: Smoothed,
    disk: Smoothed,
    gpu: Smoothed,
}

impl HaloApp {
    fn new(config: Config, theme: Theme, hotkeys: GlobalHotKeyManager, toggle_id: u32) -> Self {
        Self {
            config,
            theme,
            monitor: Monitor::new(),
            _hotkeys: hotkeys,
            toggle_id,
            visible: true,
            positioned: false,
            last_frame: Instant::now(),
            cpu: Smoothed::new(0.0, TAU),
            ram: Smoothed::new(0.0, TAU),
            swap: Smoothed::new(0.0, TAU),
            disk: Smoothed::new(0.0, TAU),
            gpu: Smoothed::new(0.0, TAU),
        }
    }

    fn poll_toggle(&mut self, ctx: &egui::Context) {
        while let Ok(event) = GlobalHotKeyEvent::receiver().try_recv() {
            if event.id == self.toggle_id && event.state == HotKeyState::Pressed {
                self.visible = !self.visible;
                ctx.send_viewport_cmd(egui::ViewportCommand::Visible(self.visible));
            }
        }
    }

    fn anchor_once(&mut self, ctx: &egui::Context) {
        if self.positioned {
            return;
        }
        if let Some(monitor) = ctx.input(|i| i.viewport().monitor_size) {
            let size = egui::Vec2::from(SIZE);
            let max_x = (monitor.x - size.x - MARGIN).max(MARGIN);
            let max_y = (monitor.y - size.y - MARGIN).max(MARGIN);
            let pos = match self.config.position {
                Position::TopLeft => egui::pos2(MARGIN, MARGIN),
                Position::TopRight => egui::pos2(max_x, MARGIN),
                Position::BottomLeft => egui::pos2(MARGIN, max_y),
                Position::BottomRight => egui::pos2(max_x, max_y),
            };
            ctx.send_viewport_cmd(egui::ViewportCommand::OuterPosition(pos));
            self.positioned = true;
        }
    }
}

/// Draw one `label + progress bar + value` row.
fn gauge(ui: &mut egui::Ui, label: &str, percent: f32, fg: Color32, accent: Color32) {
    ui.horizontal(|ui| {
        ui.label(RichText::new(format!("{label:<4}")).monospace().color(fg));
        let fraction = (percent / 100.0).clamp(0.0, 1.0);
        ui.add(
            egui::ProgressBar::new(fraction)
                .desired_width(190.0)
                .fill(accent)
                .text(
                    RichText::new(format!("{percent:>5.1}%"))
                        .monospace()
                        .color(fg),
                ),
        );
    });
}

impl eframe::App for HaloApp {
    fn clear_color(&self, _visuals: &egui::Visuals) -> [f32; 4] {
        // Fully transparent outside our rounded panel.
        [0.0, 0.0, 0.0, 0.0]
    }

    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        self.poll_toggle(ctx);
        self.anchor_once(ctx);

        let sample = self.monitor.sample();
        let dt = self.last_frame.elapsed().as_secs_f32();
        self.last_frame = Instant::now();

        self.cpu.set_target(sample.cpu_percent);
        self.ram.set_target(sample.ram_percent());
        self.swap.set_target(sample.swap_percent());
        self.disk.set_target(sample.disk_percent());
        let cpu = self.cpu.update(dt);
        let ram = self.ram.update(dt);
        let swap = self.swap.update(dt);
        let disk = self.disk.update(dt);
        let gpu = sample.gpu_percent.map(|value| {
            self.gpu.set_target(value);
            self.gpu.update(dt)
        });

        #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
        let alpha = (self.config.opacity.clamp(0.0, 1.0) * 255.0) as u8;
        let bg = self.theme.background;
        let fill = Color32::from_rgba_unmultiplied(bg.r, bg.g, bg.b, alpha);
        let fg = color32(self.theme.foreground);
        let accent = color32(self.theme.accent);

        let panel = egui::Frame::new()
            .fill(fill)
            .inner_margin(egui::Margin::same(12))
            .corner_radius(egui::CornerRadius::same(10));

        egui::CentralPanel::default().frame(panel).show(ctx, |ui| {
            ui.spacing_mut().item_spacing.y = 6.0;
            gauge(ui, "CPU", cpu, fg, accent);
            gauge(ui, "RAM", ram, fg, accent);
            gauge(ui, "SWAP", swap, fg, accent);
            gauge(ui, "DISK", disk, fg, accent);
            if let Some(gpu) = gpu {
                gauge(ui, "GPU", gpu, fg, accent);
            }
            ui.label(
                RichText::new(format!(
                    "NET ↓{} ↑{}",
                    format::rate(sample.net_rx_bps),
                    format::rate(sample.net_tx_bps),
                ))
                .monospace()
                .color(fg),
            );
            ui.label(
                RichText::new(format!("TEMP {}", format::temperature(sample.temp_celsius)))
                    .monospace()
                    .color(fg),
            );
        });

        // Repaint on the configured cadence (bounded so we never busy-loop).
        let period = self.config.refresh_ms.clamp(16, 10_000);
        ctx.request_repaint_after(Duration::from_millis(period));
    }
}
