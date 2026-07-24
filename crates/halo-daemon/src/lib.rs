//! The Halo run loop.
//!
//! `halo-daemon` ties the monitoring ([`halo_core`]), configuration
//! ([`halo_config`]) and rendering ([`halo_ui`]) crates together into a single
//! async loop: sample the system on the configured interval, hand each sample
//! to the overlay, and shut down cleanly on Ctrl-C. Keeping this orchestration
//! out of `halo-cli` lets other front-ends (a settings GUI, tests) reuse it.

use std::time::Duration;

use halo_config::Config;
use halo_core::Monitor;
use halo_themes::Theme;
use halo_ui::{Overlay, TextOverlay};

/// Run the sampling loop until interrupted with Ctrl-C.
///
/// # Errors
/// Propagates any error returned while installing the shutdown signal handler.
pub async fn run(config: Config) -> anyhow::Result<()> {
    let interval = Duration::from_millis(config.refresh_ms);
    let mut monitor = Monitor::new();
    let mut overlay = TextOverlay::new(config, Theme::minimal());
    let mut ticker = tokio::time::interval(interval);

    tracing::info!(target: "halo::daemon", "Hello Halo — starting run loop");

    loop {
        tokio::select! {
            _ = ticker.tick() => {
                let sample = monitor.sample();
                // `TextOverlay::render` is infallible; unwrap is safe here.
                overlay.render(&sample).expect("text overlay never fails");
            }
            _ = tokio::signal::ctrl_c() => {
                tracing::info!(target: "halo::daemon", "shutdown requested, stopping");
                break;
            }
        }
    }

    Ok(())
}
