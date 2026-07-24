//! The Halo run loop.
//!
//! `halo-daemon` ties monitoring ([`halo_core`]), configuration
//! ([`halo_config`]) and rendering ([`halo_ui`]) together into a single async
//! loop: sample the system on the configured interval, hand each sample to the
//! overlay, and shut down cleanly on Ctrl-C. Keeping this orchestration out of
//! `halo-cli` lets other front-ends (a settings GUI, tests) reuse it.

use std::time::Duration;

use halo_config::Config;
use halo_core::Monitor;
use halo_themes::Theme;
use halo_ui::{Overlay, TextOverlay};

/// Run the sampling loop until interrupted with Ctrl-C.
///
/// On each tick the current [`halo_core::Sample`] is rendered through the
/// overlay; the loop exits cleanly when a shutdown signal is received.
///
/// # Errors
/// Propagates any error returned while installing the Ctrl-C signal handler.
pub async fn run(config: Config) -> anyhow::Result<()> {
    let interval = Duration::from_millis(config.refresh_ms);
    let theme = Theme::by_name(&config.theme);
    let mut monitor = Monitor::new();
    let mut overlay = TextOverlay::new(config, theme);
    let mut ticker = tokio::time::interval(interval);

    tracing::info!(
        target: "halo::daemon",
        ?interval,
        "Hello Halo — starting run loop (Ctrl-C to stop)"
    );

    loop {
        tokio::select! {
            _ = ticker.tick() => {
                let sample = monitor.sample();
                // `TextOverlay` renders infallibly; the `Err` arm is unreachable.
                match overlay.render(&sample) {
                    Ok(()) => {}
                    Err(never) => match never {},
                }
            }
            result = tokio::signal::ctrl_c() => {
                result?;
                tracing::info!(target: "halo::daemon", "shutdown requested, stopping cleanly");
                break;
            }
        }
    }

    Ok(())
}

/// Launch the windowed overlay (Roadmap Phase 2).
///
/// This drives the `winit` event loop and therefore blocks the calling thread,
/// which must be the process main thread on macOS. It is deliberately not
/// `async`.
///
/// # Errors
/// Propagates any error from creating the event loop, window or hotkey manager.
#[cfg(feature = "overlay")]
pub fn run_overlay(config: Config) -> anyhow::Result<()> {
    halo_ui::overlay::run(config).map_err(|err| anyhow::anyhow!("overlay error: {err}"))
}
