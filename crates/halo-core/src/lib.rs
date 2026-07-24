//! Core monitoring primitives for the Halo HUD.
//!
//! `halo-core` owns the data model for a single [`Sample`] of the system state
//! (CPU, RAM, swap, disk, network, temperature) and the [`Monitor`] that
//! produces them. Rendering, configuration and CLI concerns live in the sibling
//! crates so this crate stays free of UI dependencies.
//!
//! The `sysinfo` backend is intentionally kept behind [`Monitor`]; direct
//! `/proc` and `/sys` readers can replace it later without changing callers.

use std::time::Instant;

use serde::{Deserialize, Serialize};
use sysinfo::{Components, Disks, Networks, System};

/// Errors returned while collecting a system sample.
#[derive(Debug, thiserror::Error)]
pub enum MonitorError {
    /// A sensor was requested but is unavailable on this platform.
    #[error("sensor `{0}` is unavailable on this platform")]
    UnavailableSensor(&'static str),
}

/// Compute `used / total` as a percentage in the `0.0..=100.0` range.
#[allow(clippy::cast_precision_loss)]
fn percent(used: u64, total: u64) -> f32 {
    if total == 0 {
        0.0
    } else {
        (used as f32 / total as f32) * 100.0
    }
}

/// A point-in-time snapshot of the metrics rendered by the HUD.
///
/// Byte counters are absolute; rates are bytes per second. Percentages are
/// derived on demand via the helper methods so widgets can format raw values
/// however they like.
#[derive(Debug, Clone, Copy, PartialEq, Serialize, Deserialize, Default)]
pub struct Sample {
    /// Total CPU usage across all cores, as a percentage (`0.0..=100.0`).
    pub cpu_percent: f32,
    /// Used physical memory, in bytes.
    pub ram_used: u64,
    /// Total physical memory, in bytes.
    pub ram_total: u64,
    /// Used swap, in bytes.
    pub swap_used: u64,
    /// Total swap, in bytes.
    pub swap_total: u64,
    /// Used disk space across mounted volumes, in bytes.
    pub disk_used: u64,
    /// Total disk space across mounted volumes, in bytes.
    pub disk_total: u64,
    /// Network receive rate, in bytes per second.
    pub net_rx_bps: u64,
    /// Network transmit rate, in bytes per second.
    pub net_tx_bps: u64,
    /// Highest reported component temperature in degrees Celsius, if any.
    pub temp_celsius: Option<f32>,
}

impl Sample {
    /// Used memory as a percentage of total memory.
    #[must_use]
    pub fn ram_percent(&self) -> f32 {
        percent(self.ram_used, self.ram_total)
    }

    /// Used swap as a percentage of total swap.
    #[must_use]
    pub fn swap_percent(&self) -> f32 {
        percent(self.swap_used, self.swap_total)
    }

    /// Used disk space as a percentage of total disk space.
    #[must_use]
    pub fn disk_percent(&self) -> f32 {
        percent(self.disk_used, self.disk_total)
    }
}

/// Collects [`Sample`]s from the running system.
///
/// A single `Monitor` keeps its sensor handles alive between samples so it can
/// derive network rates from the delta between refreshes.
pub struct Monitor {
    system: System,
    disks: Disks,
    components: Components,
    networks: Networks,
    last_refresh: Instant,
}

impl std::fmt::Debug for Monitor {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Monitor")
            .field("disks", &self.disks.len())
            .field("components", &self.components.len())
            .field("networks", &self.networks.len())
            .finish_non_exhaustive()
    }
}

impl Monitor {
    /// Create a monitor with all sensors initialised and refreshed once.
    #[must_use]
    pub fn new() -> Self {
        Self {
            system: System::new_all(),
            disks: Disks::new_with_refreshed_list(),
            components: Components::new_with_refreshed_list(),
            networks: Networks::new_with_refreshed_list(),
            last_refresh: Instant::now(),
        }
    }

    /// Refresh every sensor and return the current [`Sample`].
    ///
    /// Network rates are averaged over the time elapsed since the previous
    /// call, so calling this on a steady interval yields stable readings.
    pub fn sample(&mut self) -> Sample {
        let elapsed = self.last_refresh.elapsed().as_secs_f64().max(1e-3);

        self.system.refresh_cpu_usage();
        self.system.refresh_memory();
        self.disks.refresh(true);
        self.components.refresh(true);
        self.networks.refresh(true);
        self.last_refresh = Instant::now();

        let (disk_used, disk_total) = self.disks.iter().fold((0, 0), |(used, total), disk| {
            let disk_total = disk.total_space();
            let disk_used = disk_total.saturating_sub(disk.available_space());
            (used + disk_used, total + disk_total)
        });

        let (rx, tx) = self
            .networks
            .iter()
            .fold((0u64, 0u64), |(rx, tx), (_, data)| {
                (rx + data.received(), tx + data.transmitted())
            });

        let temp_celsius = self
            .components
            .iter()
            .filter_map(sysinfo::Component::temperature)
            .max_by(f32::total_cmp);

        #[allow(
            clippy::cast_possible_truncation,
            clippy::cast_sign_loss,
            clippy::cast_precision_loss
        )]
        let per_second = |bytes: u64| (bytes as f64 / elapsed) as u64;

        Sample {
            cpu_percent: self.system.global_cpu_usage(),
            ram_used: self.system.used_memory(),
            ram_total: self.system.total_memory(),
            swap_used: self.system.used_swap(),
            swap_total: self.system.total_swap(),
            disk_used,
            disk_total,
            net_rx_bps: per_second(rx),
            net_tx_bps: per_second(tx),
            temp_celsius,
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
    #[allow(clippy::float_cmp)] // exact, representable results
    fn percent_handles_zero_total() {
        assert_eq!(percent(10, 0), 0.0);
        assert_eq!(percent(1, 2), 50.0);
    }

    #[test]
    fn percentages_stay_in_range() {
        let sample = Monitor::new().sample();
        assert!((0.0..=100.0).contains(&sample.cpu_percent));
        assert!((0.0..=100.0).contains(&sample.ram_percent()));
        assert!((0.0..=100.0).contains(&sample.disk_percent()));
    }
}
