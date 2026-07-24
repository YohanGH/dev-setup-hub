//! Human-friendly formatting helpers shared by every overlay backend.

use halo_core::Sample;

/// Format a byte count as a compact, human-readable string (e.g. `1.5 GiB`).
#[must_use]
#[allow(clippy::cast_precision_loss)]
pub fn bytes(value: u64) -> String {
    const UNITS: [&str; 6] = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"];
    let mut size = value as f64;
    let mut unit = 0;
    while size >= 1024.0 && unit < UNITS.len() - 1 {
        size /= 1024.0;
        unit += 1;
    }
    if unit == 0 {
        format!("{value} {}", UNITS[0])
    } else {
        format!("{size:.1} {}", UNITS[unit])
    }
}

/// Format a byte-per-second rate (e.g. `2.0 MiB/s`).
#[must_use]
pub fn rate(bytes_per_second: u64) -> String {
    format!("{}/s", bytes(bytes_per_second))
}

/// Format an optional temperature reading (e.g. `52°C` or `--°C`).
#[must_use]
pub fn temperature(celsius: Option<f32>) -> String {
    celsius.map_or_else(|| "--°C".to_owned(), |t| format!("{t:.0}°C"))
}

/// Build the default single-line HUD string: CPU, RAM, disk and temperature.
#[must_use]
pub fn hud_line(sample: &Sample) -> String {
    format!(
        "CPU {:>5.1}% │ RAM {:>5.1}% │ DISK {:>5.1}% │ TEMP {}",
        sample.cpu_percent,
        sample.ram_percent(),
        sample.disk_percent(),
        temperature(sample.temp_celsius),
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bytes_scales_units() {
        assert_eq!(bytes(512), "512 B");
        assert_eq!(bytes(1024), "1.0 KiB");
        assert_eq!(bytes(1_572_864), "1.5 MiB");
    }

    #[test]
    fn temperature_handles_missing_sensor() {
        assert_eq!(temperature(None), "--°C");
        assert_eq!(temperature(Some(51.6)), "52°C");
    }
}
