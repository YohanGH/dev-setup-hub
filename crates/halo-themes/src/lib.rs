//! Theme definitions for the Halo HUD.
//!
//! A theme bundles the visual identity of the overlay — colours, typography
//! and spacing. Widgets read a [`Theme`] and never hard-code colours, so a new
//! look never touches rendering or monitoring logic.

use serde::{Deserialize, Serialize};

/// An RGBA colour with 8 bits per channel.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct Color {
    /// Red channel.
    pub r: u8,
    /// Green channel.
    pub g: u8,
    /// Blue channel.
    pub b: u8,
    /// Alpha channel (`255` = opaque).
    pub a: u8,
}

impl Color {
    /// Construct an opaque colour from RGB channels.
    #[must_use]
    pub const fn rgb(r: u8, g: u8, b: u8) -> Self {
        Self { r, g, b, a: 255 }
    }
}

/// A complete visual theme applied to the overlay.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Theme {
    /// Machine-readable theme identifier (e.g. `"minimal"`).
    pub name: String,
    /// Overlay background colour.
    pub background: Color,
    /// Primary text colour.
    pub foreground: Color,
    /// Accent colour used for gauges and highlights.
    pub accent: Color,
    /// Font family name.
    pub font_family: String,
}

impl Theme {
    /// The built-in `minimal` theme used as a fallback.
    #[must_use]
    pub fn minimal() -> Self {
        Self {
            name: "minimal".to_owned(),
            background: Color::rgb(16, 16, 20),
            foreground: Color::rgb(230, 230, 235),
            accent: Color::rgb(0, 200, 160),
            font_family: "monospace".to_owned(),
        }
    }
}

impl Default for Theme {
    fn default() -> Self {
        Self::minimal()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn minimal_theme_is_named() {
        assert_eq!(Theme::minimal().name, "minimal");
    }
}
