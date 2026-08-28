//! Configuration model for Halo.
//!
//! The HUD is driven entirely by a single `config.toml`. This crate defines
//! the strongly-typed schema, sane defaults, and (de)serialisation so no other
//! crate has to know the on-disk format.

use std::path::{Path, PathBuf};

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
    /// The configuration could not be serialised to TOML.
    #[error("failed to serialise config: {0}")]
    Serialize(#[from] toml::ser::Error),
    /// No config directory could be determined for the default path.
    #[error("no config directory found (set $XDG_CONFIG_HOME or $HOME)")]
    NoConfigDir,
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
    ///
    /// Stored as `f64` so a value like `0.55` round-trips cleanly through TOML.
    pub opacity: f64,
    /// Refresh interval in milliseconds.
    pub refresh_ms: u64,
    /// Active theme name (see `halo-themes`).
    pub theme: String,
    /// Base font size in points.
    pub font_size: u16,
    /// Enabled widgets, in display order (by id, e.g. `["cpu", "ram"]`).
    ///
    /// `None` means "use the renderer's built-in default set". An empty list
    /// hides every widget. Unknown ids are ignored by the renderer.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub widgets: Option<Vec<String>>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            position: Position::default(),
            opacity: 0.55,
            refresh_ms: 500,
            theme: "minimal".to_owned(),
            font_size: 18,
            widgets: None,
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
    pub fn load(path: impl AsRef<Path>) -> Result<Self, ConfigError> {
        let source = std::fs::read_to_string(path)?;
        Ok(Self::from_toml(&source)?.normalized())
    }

    /// Load the config from the standard location, or fall back to defaults.
    ///
    /// Looks for `$XDG_CONFIG_HOME/halo/config.toml` (or
    /// `~/.config/halo/config.toml`). A missing file is not an error — the
    /// built-in defaults are returned instead.
    ///
    /// # Errors
    /// Returns an error only if the file exists but cannot be read or parsed.
    pub fn load_default() -> Result<Self, ConfigError> {
        match default_path() {
            Some(path) if path.is_file() => Self::load(path),
            _ => Ok(Self::default()),
        }
    }

    /// Serialise the config to a pretty TOML string.
    ///
    /// # Errors
    /// Returns [`ConfigError::Serialize`] if serialisation fails.
    pub fn to_toml(&self) -> Result<String, ConfigError> {
        Ok(toml::to_string_pretty(self)?)
    }

    /// Write the config to `path`, creating parent directories as needed.
    ///
    /// This is what a settings UI (Roadmap Phase 12) or `halo init` calls so
    /// users never hand-edit the file.
    ///
    /// # Errors
    /// Returns [`ConfigError::Serialize`] or [`ConfigError::Io`] on failure.
    pub fn save(&self, path: impl AsRef<Path>) -> Result<(), ConfigError> {
        let path = path.as_ref();
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        std::fs::write(path, self.to_toml()?)?;
        Ok(())
    }

    /// Write the config to the standard location, returning the path written.
    ///
    /// # Errors
    /// Returns [`ConfigError::NoConfigDir`] if no config directory is known, or
    /// a serialisation/IO error on failure.
    pub fn save_default(&self) -> Result<PathBuf, ConfigError> {
        let path = default_path().ok_or(ConfigError::NoConfigDir)?;
        self.save(&path)?;
        Ok(path)
    }

    /// Clamp fields to sane ranges so a hand-edited file can't misbehave.
    #[must_use]
    pub fn normalized(mut self) -> Self {
        self.opacity = self.opacity.clamp(0.0, 1.0);
        self.refresh_ms = self.refresh_ms.max(MIN_REFRESH_MS);
        self.font_size = self.font_size.clamp(6, 96);
        self
    }
}

/// The lowest refresh interval accepted, guarding against a busy-loop config.
const MIN_REFRESH_MS: u64 = 50;

/// Compute the config file path under a config base directory.
fn config_path_in(base: &Path) -> PathBuf {
    base.join("halo").join("config.toml")
}

/// The platform config-file location, if a home/config directory is known.
///
/// Resolves `$XDG_CONFIG_HOME`, then `$HOME/.config`.
#[must_use]
pub fn default_path() -> Option<PathBuf> {
    let base = std::env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .filter(|p| !p.as_os_str().is_empty())
        .or_else(|| std::env::var_os("HOME").map(|home| PathBuf::from(home).join(".config")))?;
    Some(config_path_in(&base))
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

    #[test]
    #[allow(clippy::float_cmp)] // clamped to an exact bound
    fn normalize_clamps_out_of_range_fields() {
        let config = Config {
            opacity: 5.0,
            refresh_ms: 1,
            font_size: 500,
            ..Config::default()
        }
        .normalized();
        assert_eq!(config.opacity, 1.0);
        assert_eq!(config.refresh_ms, MIN_REFRESH_MS);
        assert_eq!(config.font_size, 96);
    }

    #[test]
    fn widgets_default_to_none_and_parse_as_list() {
        assert!(Config::default().widgets.is_none());
        let config = Config::from_toml("widgets = [\"cpu\", \"clock\"]").unwrap();
        assert_eq!(
            config.widgets.as_deref(),
            Some(["cpu".to_owned(), "clock".to_owned()].as_slice())
        );
    }

    #[test]
    fn config_path_is_under_halo_dir() {
        let path = config_path_in(Path::new("/home/user/.config"));
        assert!(path.ends_with("halo/config.toml"));
    }

    #[test]
    fn save_then_load_round_trips() {
        let dir = std::env::temp_dir().join(format!("halo-cfg-{}", std::process::id()));
        let path = dir.join("halo").join("config.toml");
        let original = Config {
            theme: "nord".to_owned(),
            widgets: Some(vec!["cpu".to_owned(), "clock".to_owned()]),
            ..Config::default()
        };
        original.save(&path).unwrap();
        let loaded = Config::load(&path).unwrap();
        assert_eq!(loaded, original);
        std::fs::remove_dir_all(&dir).ok();
    }
}
