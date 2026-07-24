//! Core monitoring primitives for the Halo HUD.
//!
//! `halo-core` owns the data model for a single [`Sample`] of the system state
//! (CPU, RAM, swap, disk, network, temperature) and the [`Monitor`] that
//! produces them. Rendering, configuration and CLI concerns live in the sibling
//! crates so this crate stays free of UI dependencies.
//!
//! The `sysinfo` backend is intentionally kept behind [`Monitor`]; direct
//! `/proc` and `/sys` readers can replace it later without changing callers.

use std::time::{Duration, Instant};

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
    /// GPU utilisation as a percentage, if a GPU sensor is available.
    pub gpu_percent: Option<f32>,
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

/// Per-sensor refresh cadences (Roadmap Phase 13).
///
/// Each sensor is polled at its own rhythm so the monitor never re-reads
/// everything on a single tick — fewer wakeups and lower CPU use, which is what
/// lets a fast display refresh stay cheap.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct SensorIntervals {
    /// CPU load cadence.
    pub cpu: Duration,
    /// Memory + swap cadence.
    pub memory: Duration,
    /// Disk usage cadence.
    pub disk: Duration,
    /// Network throughput cadence.
    pub network: Duration,
    /// Temperature cadence.
    pub temperature: Duration,
    /// GPU utilisation cadence.
    pub gpu: Duration,
}

impl Default for SensorIntervals {
    fn default() -> Self {
        Self {
            cpu: Duration::from_millis(250),
            memory: Duration::from_secs(2),
            disk: Duration::from_secs(5),
            network: Duration::from_secs(1),
            temperature: Duration::from_secs(2),
            gpu: Duration::from_secs(1),
        }
    }
}

/// The next time each sensor is due to refresh.
struct Deadlines {
    cpu: Instant,
    memory: Instant,
    disk: Instant,
    network: Instant,
    temperature: Instant,
    gpu: Instant,
}

/// Read GPU utilisation (0–100) from Linux DRM sysfs (AMD/Intel `amdgpu`/`i915`
/// expose `gpu_busy_percent`). Returns `None` on other platforms or when no
/// such sensor is present; NVIDIA (via NVML) is future work.
#[cfg(target_os = "linux")]
fn read_gpu_percent() -> Option<f32> {
    for card in 0..8 {
        let path = format!("/sys/class/drm/card{card}/device/gpu_busy_percent");
        if let Ok(contents) = std::fs::read_to_string(&path) {
            if let Ok(value) = contents.trim().parse::<f32>() {
                return Some(value.clamp(0.0, 100.0));
            }
        }
    }
    None
}

#[cfg(not(target_os = "linux"))]
fn read_gpu_percent() -> Option<f32> {
    None
}

/// Collects [`Sample`]s from the running system.
///
/// A single `Monitor` keeps its sensor handles alive between samples, refreshes
/// each sensor only when it is due (see [`SensorIntervals`]) and returns a
/// cached [`Sample`] updated in place, so callers can sample as often as they
/// render without paying for every sensor each time.
pub struct Monitor {
    system: System,
    disks: Disks,
    components: Components,
    networks: Networks,
    intervals: SensorIntervals,
    due: Deadlines,
    net_stamp: Instant,
    current: Sample,
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
    /// Create a monitor with the default per-sensor cadences.
    #[must_use]
    pub fn new() -> Self {
        Self::with_intervals(SensorIntervals::default())
    }

    /// Create a monitor with custom per-sensor cadences.
    #[must_use]
    pub fn with_intervals(intervals: SensorIntervals) -> Self {
        let now = Instant::now();
        Self {
            system: System::new_all(),
            disks: Disks::new_with_refreshed_list(),
            components: Components::new_with_refreshed_list(),
            networks: Networks::new_with_refreshed_list(),
            intervals,
            // Every sensor is due immediately, so the first sample is complete.
            due: Deadlines {
                cpu: now,
                memory: now,
                disk: now,
                network: now,
                temperature: now,
                gpu: now,
            },
            net_stamp: now,
            current: Sample::default(),
        }
    }

    /// The per-sensor cadences in effect.
    #[must_use]
    pub fn intervals(&self) -> SensorIntervals {
        self.intervals
    }

    /// Refresh whichever sensors are due and return the current [`Sample`].
    ///
    /// Sensors not yet due keep their cached value, so this is cheap to call at
    /// the display refresh rate. Network rates are averaged over the time since
    /// the network sensor was last refreshed.
    pub fn sample(&mut self) -> Sample {
        let now = Instant::now();

        if now >= self.due.cpu {
            self.system.refresh_cpu_usage();
            self.current.cpu_percent = self.system.global_cpu_usage();
            self.due.cpu = now + self.intervals.cpu;
        }

        if now >= self.due.memory {
            self.system.refresh_memory();
            self.current.ram_used = self.system.used_memory();
            self.current.ram_total = self.system.total_memory();
            self.current.swap_used = self.system.used_swap();
            self.current.swap_total = self.system.total_swap();
            self.due.memory = now + self.intervals.memory;
        }

        if now >= self.due.disk {
            self.disks.refresh(true);
            let (used, total) = self.disks.iter().fold((0, 0), |(used, total), disk| {
                let disk_total = disk.total_space();
                let disk_used = disk_total.saturating_sub(disk.available_space());
                (used + disk_used, total + disk_total)
            });
            self.current.disk_used = used;
            self.current.disk_total = total;
            self.due.disk = now + self.intervals.disk;
        }

        if now >= self.due.network {
            self.networks.refresh(true);
            let elapsed = (now - self.net_stamp).as_secs_f64().max(1e-3);
            let (rx, tx) = self
                .networks
                .iter()
                .fold((0u64, 0u64), |(rx, tx), (_, data)| {
                    (rx + data.received(), tx + data.transmitted())
                });
            #[allow(
                clippy::cast_possible_truncation,
                clippy::cast_sign_loss,
                clippy::cast_precision_loss
            )]
            let per_second = |bytes: u64| (bytes as f64 / elapsed) as u64;
            self.current.net_rx_bps = per_second(rx);
            self.current.net_tx_bps = per_second(tx);
            self.net_stamp = now;
            self.due.network = now + self.intervals.network;
        }

        if now >= self.due.temperature {
            self.components.refresh(true);
            self.current.temp_celsius = self
                .components
                .iter()
                .filter_map(sysinfo::Component::temperature)
                .max_by(f32::total_cmp);
            self.due.temperature = now + self.intervals.temperature;
        }

        if now >= self.due.gpu {
            self.current.gpu_percent = read_gpu_percent();
            self.due.gpu = now + self.intervals.gpu;
        }

        self.current
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

    #[test]
    fn default_intervals_match_documented_cadence() {
        let intervals = SensorIntervals::default();
        assert_eq!(intervals.cpu, Duration::from_millis(250));
        assert_eq!(intervals.memory, Duration::from_secs(2));
        assert_eq!(intervals.disk, Duration::from_secs(5));
        assert_eq!(intervals.network, Duration::from_secs(1));
    }

    #[test]
    #[allow(clippy::float_cmp)] // cached values are byte-identical
    fn back_to_back_samples_reuse_cache() {
        let mut monitor = Monitor::new();
        let first = monitor.sample();
        // Called immediately: no sensor is due again, so values are cached.
        let second = monitor.sample();
        assert_eq!(first.cpu_percent, second.cpu_percent);
        assert_eq!(first.ram_used, second.ram_used);
        assert_eq!(first.disk_total, second.disk_total);
    }
}
