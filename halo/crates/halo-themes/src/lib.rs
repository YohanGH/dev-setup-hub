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

    /// Construct a colour with an explicit alpha channel.
    #[must_use]
    pub const fn rgba(r: u8, g: u8, b: u8, a: u8) -> Self {
        Self { r, g, b, a }
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

    /// Neon-on-black cyberpunk look.
    #[must_use]
    pub fn cyberpunk() -> Self {
        Self {
            name: "cyberpunk".to_owned(),
            background: Color::rgba(10, 0, 20, 220),
            foreground: Color::rgb(0, 255, 200),
            accent: Color::rgb(255, 0, 160),
            font_family: "monospace".to_owned(),
        }
    }

    /// Green phosphor terminal aesthetic.
    #[must_use]
    pub fn terminal() -> Self {
        Self {
            name: "terminal".to_owned(),
            background: Color::rgb(0, 0, 0),
            foreground: Color::rgb(0, 230, 0),
            accent: Color::rgb(0, 160, 0),
            font_family: "monospace".to_owned(),
        }
    }

    /// Frosted, translucent panel.
    #[must_use]
    pub fn glass() -> Self {
        Self {
            name: "glass".to_owned(),
            background: Color::rgba(240, 240, 250, 90),
            foreground: Color::rgb(20, 20, 30),
            accent: Color::rgb(90, 140, 255),
            font_family: "sans-serif".to_owned(),
        }
    }

    /// The [Nord](https://www.nordtheme.com) palette.
    #[must_use]
    pub fn nord() -> Self {
        Self {
            name: "nord".to_owned(),
            background: Color::rgb(46, 52, 64),
            foreground: Color::rgb(216, 222, 233),
            accent: Color::rgb(136, 192, 208),
            font_family: "sans-serif".to_owned(),
        }
    }

    /// Pure-black theme for OLED panels (no backlight bleed).
    #[must_use]
    pub fn oled() -> Self {
        Self {
            name: "oled".to_owned(),
            background: Color::rgb(0, 0, 0),
            foreground: Color::rgb(255, 255, 255),
            accent: Color::rgb(120, 120, 120),
            font_family: "monospace".to_owned(),
        }
    }

    /// Greyscale, distraction-free theme.
    #[must_use]
    pub fn monochrome() -> Self {
        Self {
            name: "monochrome".to_owned(),
            background: Color::rgb(18, 18, 18),
            foreground: Color::rgb(220, 220, 220),
            accent: Color::rgb(150, 150, 150),
            font_family: "monospace".to_owned(),
        }
    }

    /// Look up a built-in theme by name, falling back to [`Theme::minimal`].
    #[must_use]
    pub fn by_name(name: &str) -> Self {
        builtins()
            .into_iter()
            .find(|theme| theme.name == name)
            .unwrap_or_else(Self::minimal)
    }
}

/// All themes shipped with Halo, in presentation order.
#[must_use]
pub fn builtins() -> Vec<Theme> {
    vec![
        Theme::minimal(),
        Theme::cyberpunk(),
        Theme::terminal(),
        Theme::glass(),
        Theme::nord(),
        Theme::oled(),
        Theme::monochrome(),
    ]
}

/// The names of every built-in theme.
#[must_use]
pub fn names() -> Vec<String> {
    builtins().into_iter().map(|theme| theme.name).collect()
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

    #[test]
    fn every_builtin_resolves_by_its_name() {
        for theme in builtins() {
            assert_eq!(Theme::by_name(&theme.name), theme);
        }
    }

    #[test]
    fn unknown_theme_falls_back_to_minimal() {
        assert_eq!(Theme::by_name("nope"), Theme::minimal());
    }

    #[test]
    fn builtin_names_are_unique() {
        let mut names = names();
        let count = names.len();
        names.sort();
        names.dedup();
        assert_eq!(names.len(), count, "duplicate theme name");
    }
}
