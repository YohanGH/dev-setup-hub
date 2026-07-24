//! Independent HUD widgets (Roadmap Phase 7).
//!
//! Each widget renders one metric from a [`Sample`] into a short string and is
//! completely self-contained, so widgets can be enabled, disabled or reordered
//! (Phase 10) without touching each other. The overlay composes a line from an
//! ordered set of widgets via [`render_line`].

use std::time::{SystemTime, UNIX_EPOCH};

use halo_core::Sample;

use crate::format::{rate, temperature};

/// A self-contained HUD element that renders one metric.
///
/// The `Debug` bound lets overlays holding `Box<dyn Widget>` derive `Debug`.
pub trait Widget: std::fmt::Debug {
    /// Stable identifier used in configuration (e.g. `"cpu"`).
    fn id(&self) -> &'static str;

    /// Render the widget's current value for `sample` as a display string.
    fn render(&self, sample: &Sample) -> String;
}

/// CPU load widget.
#[derive(Debug, Clone, Copy)]
pub struct Cpu;
/// Physical memory usage widget.
#[derive(Debug, Clone, Copy)]
pub struct Ram;
/// Swap usage widget.
#[derive(Debug, Clone, Copy)]
pub struct Swap;
/// Aggregate disk usage widget.
#[derive(Debug, Clone, Copy)]
pub struct Disk;
/// Network throughput widget (receive / transmit).
#[derive(Debug, Clone, Copy)]
pub struct Net;
/// Highest component temperature widget.
#[derive(Debug, Clone, Copy)]
pub struct Temp;
/// GPU utilisation widget (Linux DRM sysfs; `--` where unavailable).
#[derive(Debug, Clone, Copy)]
pub struct Gpu;
/// Wall-clock widget (UTC until a timezone source is added).
#[derive(Debug, Clone, Copy)]
pub struct Clock;

impl Widget for Cpu {
    fn id(&self) -> &'static str {
        "cpu"
    }
    fn render(&self, sample: &Sample) -> String {
        format!("CPU {:>5.1}%", sample.cpu_percent)
    }
}

impl Widget for Ram {
    fn id(&self) -> &'static str {
        "ram"
    }
    fn render(&self, sample: &Sample) -> String {
        format!("RAM {:>5.1}%", sample.ram_percent())
    }
}

impl Widget for Swap {
    fn id(&self) -> &'static str {
        "swap"
    }
    fn render(&self, sample: &Sample) -> String {
        format!("SWAP {:>5.1}%", sample.swap_percent())
    }
}

impl Widget for Disk {
    fn id(&self) -> &'static str {
        "disk"
    }
    fn render(&self, sample: &Sample) -> String {
        format!("DISK {:>5.1}%", sample.disk_percent())
    }
}

impl Widget for Net {
    fn id(&self) -> &'static str {
        "net"
    }
    fn render(&self, sample: &Sample) -> String {
        format!(
            "NET ↓{} ↑{}",
            rate(sample.net_rx_bps),
            rate(sample.net_tx_bps)
        )
    }
}

impl Widget for Temp {
    fn id(&self) -> &'static str {
        "temp"
    }
    fn render(&self, sample: &Sample) -> String {
        format!("TEMP {}", temperature(sample.temp_celsius))
    }
}

impl Widget for Gpu {
    fn id(&self) -> &'static str {
        "gpu"
    }
    fn render(&self, sample: &Sample) -> String {
        // `None` when no GPU sensor is available (non-Linux, or NVIDIA-only).
        match sample.gpu_percent {
            Some(percent) => format!("GPU {percent:>5.1}%"),
            None => "GPU   --%".to_owned(),
        }
    }
}

impl Widget for Clock {
    fn id(&self) -> &'static str {
        "clock"
    }
    fn render(&self, _sample: &Sample) -> String {
        let secs = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .map_or(0, |d| d.as_secs());
        let (h, m, s) = (secs / 3600 % 24, secs / 60 % 60, secs % 60);
        format!("{h:02}:{m:02}:{s:02}")
    }
}

/// Look up a widget by its identifier.
#[must_use]
pub fn by_id(id: &str) -> Option<Box<dyn Widget>> {
    let widget: Box<dyn Widget> = match id {
        "cpu" => Box::new(Cpu),
        "ram" => Box::new(Ram),
        "swap" => Box::new(Swap),
        "disk" => Box::new(Disk),
        "net" => Box::new(Net),
        "temp" => Box::new(Temp),
        "gpu" => Box::new(Gpu),
        "clock" => Box::new(Clock),
        _ => return None,
    };
    Some(widget)
}

/// The widgets shown by default, in order.
#[must_use]
pub fn default_ids() -> Vec<&'static str> {
    vec!["cpu", "ram", "swap", "disk", "net", "temp"]
}

/// Render an ordered set of widgets into a single ` │ `-separated line.
#[must_use]
pub fn render_line(widgets: &[Box<dyn Widget>], sample: &Sample) -> String {
    widgets
        .iter()
        .map(|w| w.render(sample))
        .collect::<Vec<_>>()
        .join(" │ ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn every_default_id_resolves() {
        for id in default_ids() {
            assert!(by_id(id).is_some(), "unknown default widget {id}");
        }
    }

    #[test]
    fn unknown_id_is_none() {
        assert!(by_id("does-not-exist").is_none());
    }

    #[test]
    fn render_line_joins_widgets() {
        let widgets: Vec<Box<dyn Widget>> = vec![Box::new(Cpu), Box::new(Ram)];
        let line = render_line(&widgets, &Sample::default());
        assert!(line.contains("CPU"));
        assert!(line.contains(" │ "));
        assert!(line.contains("RAM"));
    }
}
