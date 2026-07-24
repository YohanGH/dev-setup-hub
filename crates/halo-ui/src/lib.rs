//! Overlay rendering for Halo.
//!
//! `halo-ui` turns a [`halo_core::Sample`] into pixels on a transparent,
//! borderless, always-on-top, click-through surface. The concrete GPU backend
//! (egui/Slint on top of wgpu) is deliberately kept behind this crate's API so
//! the rest of Halo depends only on the [`Overlay`] trait, never on a toolkit.

use halo_config::Config;
use halo_core::Sample;
use halo_themes::Theme;

/// A surface that can present system [`Sample`]s to the user.
pub trait Overlay {
    /// Error type produced by overlay operations.
    type Error;

    /// Render a single frame for the given sample.
    ///
    /// # Errors
    /// Implementations return their backend-specific error if the frame could
    /// not be presented.
    fn render(&mut self, sample: &Sample) -> Result<(), Self::Error>;
}

/// A headless overlay that formats samples as text.
///
/// It carries no windowing dependencies, which makes it useful for early
/// bring-up (Phase 1–3) and for tests. It is replaced by a GPU overlay once
/// the windowing backend lands.
#[derive(Debug)]
pub struct TextOverlay {
    theme: Theme,
    config: Config,
}

impl TextOverlay {
    /// Create a text overlay from a config and theme.
    #[must_use]
    pub fn new(config: Config, theme: Theme) -> Self {
        Self { theme, config }
    }

    /// Format a sample into a one-line HUD string.
    #[must_use]
    pub fn format(&self, sample: &Sample) -> String {
        let _ = (&self.theme, &self.config);
        format!(
            "CPU {:>5.1}% | RAM {:>5.1}%",
            sample.cpu_percent, sample.ram_percent
        )
    }
}

impl Overlay for TextOverlay {
    type Error = std::convert::Infallible;

    fn render(&mut self, sample: &Sample) -> Result<(), Self::Error> {
        tracing::info!(target: "halo::overlay", "{}", self.format(sample));
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn format_reports_cpu_and_ram() {
        let overlay = TextOverlay::new(Config::default(), Theme::minimal());
        let line = overlay.format(&Sample::default());
        assert!(line.contains("CPU"));
        assert!(line.contains("RAM"));
    }
}
