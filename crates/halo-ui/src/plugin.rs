//! Plugin system (Roadmap Phase 11).
//!
//! A [`Plugin`] contributes extra [`Widget`]s (Weather, Spotify, Docker, Git,
//! battery, …) without any change to the core: register plugins in a
//! [`PluginRegistry`], and widget ids resolve from plugins first, then fall back
//! to the built-in widgets. This keeps the resolution path uniform whether a
//! widget ships with Halo or comes from a plugin.
//!
//! Only safe, in-process plugins are supported today. Loading external plugins
//! from shared libraries is deliberately out of scope for now (it requires
//! `unsafe` FFI and a stable ABI) and is tracked as future work.

use crate::widget::{self, Widget};

/// A source of additional widgets.
pub trait Plugin: std::fmt::Debug {
    /// Stable, human-readable plugin name (e.g. `"battery"`).
    fn name(&self) -> &'static str;

    /// The widgets this plugin contributes.
    fn widgets(&self) -> Vec<Box<dyn Widget>>;
}

/// Holds registered plugins and resolves widget ids across them and the core.
#[derive(Debug, Default)]
pub struct PluginRegistry {
    plugins: Vec<Box<dyn Plugin>>,
}

impl PluginRegistry {
    /// Create an empty registry.
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Register a plugin.
    pub fn register(&mut self, plugin: Box<dyn Plugin>) {
        self.plugins.push(plugin);
    }

    /// Number of registered plugins.
    #[must_use]
    pub fn len(&self) -> usize {
        self.plugins.len()
    }

    /// Whether no plugins are registered.
    #[must_use]
    pub fn is_empty(&self) -> bool {
        self.plugins.is_empty()
    }

    /// Resolve a widget by id: plugins first, then the built-in widgets.
    #[must_use]
    pub fn resolve(&self, id: &str) -> Option<Box<dyn Widget>> {
        for plugin in &self.plugins {
            if let Some(w) = plugin.widgets().into_iter().find(|w| w.id() == id) {
                return Some(w);
            }
        }
        widget::by_id(id)
    }

    /// Ids of every widget contributed by registered plugins.
    #[must_use]
    pub fn plugin_widget_ids(&self) -> Vec<&'static str> {
        self.plugins
            .iter()
            .flat_map(|p| p.widgets().into_iter().map(|w| w.id()))
            .collect()
    }
}

/// A minimal example plugin contributing a static `greeting` widget.
///
/// It exists to exercise the plugin path end to end and to serve as a template
/// for real plugins (Weather, Spotify, …).
#[derive(Debug, Clone, Copy)]
pub struct ExamplePlugin;

#[derive(Debug, Clone, Copy)]
struct Greeting;

impl Widget for Greeting {
    fn id(&self) -> &'static str {
        "greeting"
    }
    fn render(&self, _sample: &halo_core::Sample) -> String {
        "HALO".to_owned()
    }
}

impl Plugin for ExamplePlugin {
    fn name(&self) -> &'static str {
        "example"
    }
    fn widgets(&self) -> Vec<Box<dyn Widget>> {
        vec![Box::new(Greeting)]
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use halo_core::Sample;

    #[test]
    fn resolves_plugin_widget() {
        let mut registry = PluginRegistry::new();
        registry.register(Box::new(ExamplePlugin));
        assert_eq!(registry.len(), 1);
        let widget = registry.resolve("greeting").expect("plugin widget");
        assert_eq!(widget.render(&Sample::default()), "HALO");
    }

    #[test]
    fn falls_back_to_builtin_widgets() {
        let registry = PluginRegistry::new();
        assert!(registry.resolve("cpu").is_some());
        assert!(registry.resolve("nonexistent").is_none());
    }
}
