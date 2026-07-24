//! Core monitoring primitives for the Halo HUD.
//!
//! `halo-core` owns the data model for a single sample of the system state
//! (CPU, RAM, network, temperature, …) and the scheduler that decides how
//! often each sensor is refreshed. Rendering, configuration and CLI concerns
//! live in the sibling crates so this crate stays free of UI dependencies.

use serde::{Deserialize, Serialize};

/// Errors returned while collecting a system sample.
#[derive(Debug, thiserror::Error)]
pub enum MonitorError {
    /// A sensor was requested but is unavailable on this platform.
    #[error("sensor `{0}` is unavailable on this platform")]
    UnavailableSensor(&'static str),
}

/// A point-in-time snapshot of the metrics rendered by the HUD.
///
/// Percentages are expressed in the `0.0..=100.0` range and byte-rates in
/// bytes per second so that widgets can format them however they like.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize, Default)]
pub struct Sample {
    /// Total CPU usage across all cores, as a percentage.
    pub cpu_percent: f32,
    /// Used memory as a percentage of total memory.
    pub ram_percent: f32,
    /// Network receive rate in bytes per second.
    pub net_rx_bps: u64,
    /// Network transmit rate in bytes per second.
    pub net_tx_bps: u64,
    /// Highest reported component temperature in degrees Celsius, if any.
    pub temp_celsius: Option<f32>,
}

/// Collects [`Sample`]s from the running system.
///
/// This is intentionally a thin wrapper for now; direct `/proc` and `/sys`
/// readers can replace the `sysinfo` backend later without changing callers.
#[derive(Debug)]
pub struct Monitor {
    system: sysinfo::System,
}

impl Monitor {
    /// Create a monitor with all sensors initialised.
    #[must_use]
    pub fn new() -> Self {
        Self {
            system: sysinfo::System::new_all(),
        }
    }

    /// Refresh the backing state and return the current [`Sample`].
    pub fn sample(&mut self) -> Sample {
        self.system.refresh_cpu_usage();
        self.system.refresh_memory();

        let total = self.system.total_memory();
        let ram_percent = if total == 0 {
            0.0
        } else {
            (self.system.used_memory() as f32 / total as f32) * 100.0
        };

        Sample {
            cpu_percent: self.system.global_cpu_usage(),
            ram_percent,
            ..Sample::default()
        }
    }
}

impl Default for Monitor {
    fn default() -> Self {
        Self::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn percentages_stay_in_range() {
        let sample = Monitor::new().sample();
        assert!((0.0..=100.0).contains(&sample.cpu_percent));
        assert!((0.0..=100.0).contains(&sample.ram_percent));
    }
}
