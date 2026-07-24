//! Animation primitives (Roadmap Phase 9).
//!
//! Widgets should never jump between values. This module provides the maths for
//! smooth transitions — easing curves and a framerate-independent exponential
//! [`Smoothed`] value — so a reading moving from 20% to 40% eases across frames
//! instead of snapping. The visual layer (fade, glow) applies these once the GPU
//! renderer lands; the interpolation itself lives and is tested here.

/// Linear interpolation between `a` and `b` at `t` in `0.0..=1.0`.
#[must_use]
pub fn lerp(a: f32, b: f32, t: f32) -> f32 {
    a + (b - a) * t.clamp(0.0, 1.0)
}

/// Easing curves applied to a normalised progress value.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Easing {
    /// Constant rate.
    Linear,
    /// Decelerates toward the end.
    EaseOut,
    /// Accelerates then decelerates (the default, most natural for a HUD).
    #[default]
    EaseInOut,
}

impl Easing {
    /// Map linear progress `t` (`0.0..=1.0`) through the curve.
    #[must_use]
    pub fn apply(self, t: f32) -> f32 {
        let t = t.clamp(0.0, 1.0);
        match self {
            Easing::Linear => t,
            Easing::EaseOut => 1.0 - (1.0 - t) * (1.0 - t),
            Easing::EaseInOut => {
                if t < 0.5 {
                    2.0 * t * t
                } else {
                    let f = -2.0 * t + 2.0;
                    1.0 - f * f / 2.0
                }
            }
        }
    }
}

/// A value that eases toward a moving target, avoiding abrupt jumps.
///
/// Uses exponential smoothing with time constant `tau` (seconds): each
/// [`update`](Smoothed::update) advances the current value a fraction
/// `1 - e^(-dt/tau)` of the way to the target, which is independent of the frame
/// rate. A larger `tau` is slower and smoother.
#[derive(Debug, Clone, Copy)]
pub struct Smoothed {
    current: f32,
    target: f32,
    tau: f32,
}

impl Smoothed {
    /// Create a smoother seeded at `value` with time constant `tau` seconds.
    #[must_use]
    pub fn new(value: f32, tau: f32) -> Self {
        Self {
            current: value,
            target: value,
            tau: tau.max(f32::EPSILON),
        }
    }

    /// Set the value the smoother eases toward.
    pub fn set_target(&mut self, target: f32) {
        self.target = target;
    }

    /// The current displayed value.
    #[must_use]
    pub fn value(&self) -> f32 {
        self.current
    }

    /// Advance by `dt` seconds and return the new current value.
    pub fn update(&mut self, dt: f32) -> f32 {
        let alpha = 1.0 - (-dt.max(0.0) / self.tau).exp();
        self.current += (self.target - self.current) * alpha;
        self.current
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn lerp_endpoints_and_midpoint() {
        assert!((lerp(0.0, 10.0, 0.0) - 0.0).abs() < 1e-6);
        assert!((lerp(0.0, 10.0, 1.0) - 10.0).abs() < 1e-6);
        assert!((lerp(0.0, 10.0, 0.5) - 5.0).abs() < 1e-6);
    }

    #[test]
    fn easing_preserves_bounds() {
        for easing in [Easing::Linear, Easing::EaseOut, Easing::EaseInOut] {
            assert!((easing.apply(0.0)).abs() < 1e-6);
            assert!((easing.apply(1.0) - 1.0).abs() < 1e-6);
            let mid = easing.apply(0.5);
            assert!((0.0..=1.0).contains(&mid));
        }
    }

    #[test]
    fn smoothed_approaches_target_without_overshoot() {
        let mut value = Smoothed::new(20.0, 0.25);
        value.set_target(40.0);
        let mut previous = value.value();
        for _ in 0..100 {
            let now = value.update(0.05);
            // Monotonic increase, never past the target.
            assert!(now >= previous - 1e-3);
            assert!(now <= 40.0 + 1e-3);
            previous = now;
        }
        assert!((value.value() - 40.0).abs() < 0.5);
    }
}
