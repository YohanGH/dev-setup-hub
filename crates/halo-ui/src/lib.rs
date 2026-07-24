//! Overlay rendering for Halo.
//!
//! `halo-ui` turns a [`halo_core::Sample`] into a presentation. Two things live
//! here: the [`Overlay`] trait every backend implements, and [`TextOverlay`], a
//! headless text backend used for early bring-up (Phase 1) and tests. The GPU
//! overlay (Phase 2+) implements the same trait so the rest of Halo depends only
//! on [`Overlay`], never on a windowing toolkit.

pub mod format;

#[cfg(feature = "overlay")]
pub mod overlay;

use halo_config::Config;
use halo_core::Sample;
use halo_themes::Theme;

pub use format::hud_line;

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

/// A headless overlay that formats samples as a single line of text.
///
/// It carries no windowing dependencies, which makes it the renderer for the
/// terminal phase and a convenient stand-in in tests.
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
        // Config and theme will drive column selection and colour once the GPU
        // backend lands; the text backend renders the full default line.
        let _ = (&self.theme, &self.config);
        hud_line(sample)
    }
}

impl Overlay for TextOverlay {
    type Error = std::convert::Infallible;

    fn render(&mut self, sample: &Sample) -> Result<(), Self::Error> {
        tracing::info!(target: "halo::hud", "{}", self.format(sample));
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn format_reports_all_columns() {
        let overlay = TextOverlay::new(Config::default(), Theme::minimal());
        let line = overlay.format(&Sample::default());
        for column in ["CPU", "RAM", "SWAP", "DISK", "NET", "TEMP"] {
            assert!(line.contains(column), "missing column {column} in {line:?}");
        }
    }
}
