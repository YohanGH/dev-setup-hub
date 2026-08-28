//! Graphical settings window (Roadmap Phase 12).
//!
//! An `eframe`/`egui` window to edit the configuration — position, opacity,
//! refresh rate, font size and theme — with a live preview and a Save button
//! that writes `config.toml` via [`Config::save_default`], so the file is never
//! hand-edited. Gated behind the `gui` feature; requires a desktop session.

use std::error::Error;

use eframe::egui::{self, Color32, RichText};
use halo_config::{Config, Position};
use halo_themes::Theme;

/// Open the settings window seeded with `config`.
///
/// # Errors
/// Returns an error if the windowing backend fails to start.
pub fn run(config: Config) -> Result<(), Box<dyn Error>> {
    let viewport = egui::ViewportBuilder::default()
        .with_title("Halo — Settings")
        .with_inner_size([440.0, 380.0]);
    let options = eframe::NativeOptions {
        viewport,
        ..Default::default()
    };
    eframe::run_native(
        "halo-settings",
        options,
        Box::new(move |_cc| Ok(Box::new(SettingsApp::new(config)))),
    )?;
    Ok(())
}

struct SettingsApp {
    config: Config,
    status: String,
}

impl SettingsApp {
    fn new(config: Config) -> Self {
        Self {
            config,
            status: String::new(),
        }
    }
}

impl eframe::App for SettingsApp {
    fn update(&mut self, ctx: &egui::Context, _frame: &mut eframe::Frame) {
        egui::CentralPanel::default().show(ctx, |ui| {
            ui.heading("Halo — Settings");
            ui.separator();

            egui::Grid::new("settings").num_columns(2).show(ui, |ui| {
                ui.label("Position");
                egui::ComboBox::from_id_salt("position")
                    .selected_text(format!("{:?}", self.config.position))
                    .show_ui(ui, |ui| {
                        for position in [
                            Position::TopLeft,
                            Position::TopRight,
                            Position::BottomLeft,
                            Position::BottomRight,
                        ] {
                            ui.selectable_value(
                                &mut self.config.position,
                                position,
                                format!("{position:?}"),
                            );
                        }
                    });
                ui.end_row();

                ui.label("Theme");
                egui::ComboBox::from_id_salt("theme")
                    .selected_text(&self.config.theme)
                    .show_ui(ui, |ui| {
                        for name in halo_themes::names() {
                            ui.selectable_value(&mut self.config.theme, name.clone(), name);
                        }
                    });
                ui.end_row();

                ui.label("Opacity");
                ui.add(egui::Slider::new(&mut self.config.opacity, 0.0..=1.0));
                ui.end_row();

                ui.label("Refresh (ms)");
                ui.add(egui::Slider::new(&mut self.config.refresh_ms, 50..=2000));
                ui.end_row();

                ui.label("Font size");
                ui.add(egui::Slider::new(&mut self.config.font_size, 6..=96));
                ui.end_row();
            });

            ui.separator();
            ui.label("Preview");
            preview(ui, &self.config);

            ui.separator();
            if ui.button("Save to config.toml").clicked() {
                match self.config.clone().normalized().save_default() {
                    Ok(path) => self.status = format!("Saved to {}", path.display()),
                    Err(err) => self.status = format!("Error: {err}"),
                }
            }
            if !self.status.is_empty() {
                ui.label(&self.status);
            }
        });
    }
}

/// Draw a small themed HUD preview reflecting the current selections.
fn preview(ui: &mut egui::Ui, config: &Config) {
    let theme = Theme::by_name(&config.theme);
    let bg = theme.background;
    #[allow(clippy::cast_possible_truncation, clippy::cast_sign_loss)]
    let alpha = (config.opacity.clamp(0.0, 1.0) * 255.0) as u8;
    let fill = Color32::from_rgba_unmultiplied(bg.r, bg.g, bg.b, alpha);
    let fg = Color32::from_rgba_unmultiplied(
        theme.foreground.r,
        theme.foreground.g,
        theme.foreground.b,
        theme.foreground.a,
    );

    egui::Frame::new()
        .fill(fill)
        .inner_margin(egui::Margin::same(10))
        .corner_radius(egui::CornerRadius::same(8))
        .show(ui, |ui| {
            ui.label(
                RichText::new("CPU  23.0% │ RAM  58.0% │ NET ↓2.0 MiB/s")
                    .monospace()
                    .size(f32::from(config.font_size).clamp(8.0, 28.0))
                    .color(fg),
            );
        });
}
