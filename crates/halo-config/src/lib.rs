//! Configuration model for Halo.
//!
//! The HUD is driven entirely by a single `config.toml`. This crate defines
//! the strongly-typed schema, sane defaults, and (de)serialisation so no other
//! crate has to know the on-disk format.

use serde::{Deserialize, Serialize};

/// Errors raised while loading or parsing configuration.
#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    /// The configuration file could not be read.
    #[error("failed to read config: {0}")]
    Io(#[from] std::io::Error),
    /// The configuration file was not valid TOML or violated the schema.
    #[error("failed to parse config: {0}")]
    Parse(#[from] toml::de::Error),
}

/// Where the HUD anchors itself on screen.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "kebab-case")]
pub enum Position {
    /// Top-left corner.
    TopLeft,
    /// Top-right corner (the default).
    #[default]
    TopRight,
    /// Bottom-left corner.
    BottomLeft,
    /// Bottom-right corner.
    BottomRight,
}

/// The full, validated Halo configuration.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(default)]
pub struct Config {
    /// Anchor position of the overlay.
    pub position: Position,
    /// Overlay opacity in the `0.0..=1.0` range.
    pub opacity: f32,
    /// Refresh interval in milliseconds.
    pub refresh_ms: u64,
    /// Active theme name (see `halo-themes`).
    pub theme: String,
    /// Base font size in points.
    pub font_size: u16,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            position: Position::default(),
            opacity: 0.55,
            refresh_ms: 500,
            theme: "minimal".to_owned(),
            font_size: 18,
        }
    }
}

impl Config {
    /// Parse a [`Config`] from a TOML string.
    ///
    /// # Errors
    /// Returns [`ConfigError::Parse`] if the string is not valid TOML or does
    /// not match the schema.
    pub fn from_toml(source: &str) -> Result<Self, ConfigError> {
        Ok(toml::from_str(source)?)
    }

    /// Load a [`Config`] from a file on disk.
    ///
    /// # Errors
    /// Returns [`ConfigError::Io`] if the file cannot be read and
    /// [`ConfigError::Parse`] if its contents are invalid.
    pub fn load(path: impl AsRef<std::path::Path>) -> Result<Self, ConfigError> {
        let source = std::fs::read_to_string(path)?;
        Self::from_toml(&source)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_match_documented_values() {
        let config = Config::default();
        assert_eq!(config.position, Position::TopRight);
        assert_eq!(config.refresh_ms, 500);
    }

    #[test]
    fn partial_config_falls_back_to_defaults() {
        let config = Config::from_toml("theme = \"nord\"").unwrap();
        assert_eq!(config.theme, "nord");
        assert_eq!(config.font_size, 18);
    }
}
