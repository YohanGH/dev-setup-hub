//! Windowed overlay backend (Roadmap Phase 2).
//!
//! Creates the Halo surface: a **transparent**, **borderless**,
//! **always-on-top**, **click-through** window anchored to a screen corner,
//! plus a **global hotkey** that toggles its visibility. This module owns the
//! window *properties*; per-pixel content (text, gauges, animations) is drawn
//! by the GPU renderer introduced in a later phase, so for now the surface is
//! intentionally empty — the compositor shows it as fully transparent.
//!
//! This backend is gated behind the `overlay` feature and requires a desktop
//! session to run (X11, Wayland, macOS or Windows). On Wayland, precise corner
//! anchoring ultimately needs the `wlr-layer-shell` protocol; until then we
//! best-effort position via the window's current monitor.

use std::error::Error;

use global_hotkey::{
    hotkey::{Code, HotKey, Modifiers},
    GlobalHotKeyEvent, GlobalHotKeyManager,
};
use halo_config::{Config, Position};
use winit::application::ApplicationHandler;
use winit::dpi::{LogicalSize, PhysicalPosition};
use winit::event::WindowEvent;
use winit::event_loop::{ActiveEventLoop, ControlFlow, EventLoop};
use winit::keyboard::{KeyCode, PhysicalKey};
use winit::window::{Window, WindowId, WindowLevel};

/// Default overlay size in logical pixels. Kept small; a real layout arrives
/// with the widget system.
const DEFAULT_SIZE: LogicalSize<f64> = LogicalSize::new(320.0, 96.0);
/// Margin from the screen edge, in physical pixels.
const EDGE_MARGIN: i32 = 24;

/// Launch the overlay window and run the event loop until the user quits.
///
/// The loop exits when the window is closed or `Escape` is pressed. The
/// registered global hotkey (`Ctrl+Alt+H`) toggles the overlay's visibility.
///
/// # Errors
/// Returns an error if the event loop, window or hotkey manager cannot be
/// created.
pub fn run(config: Config) -> Result<(), Box<dyn Error>> {
    let event_loop = EventLoop::new()?;
    // The overlay is idle most of the time; wait for events rather than spin.
    event_loop.set_control_flow(ControlFlow::Wait);

    // Register the toggle hotkey before entering the loop so it works even
    // while the window is hidden.
    let manager = GlobalHotKeyManager::new()?;
    let toggle = HotKey::new(Some(Modifiers::CONTROL | Modifiers::ALT), Code::KeyH);
    manager.register(toggle)?;

    let mut app = OverlayApp {
        config,
        toggle_id: toggle.id(),
        window: None,
        visible: true,
    };

    event_loop.run_app(&mut app)?;
    Ok(())
}

struct OverlayApp {
    config: Config,
    toggle_id: u32,
    window: Option<Window>,
    visible: bool,
}

impl OverlayApp {
    fn build_window(&self, event_loop: &ActiveEventLoop) -> Result<Window, Box<dyn Error>> {
        let attributes = Window::default_attributes()
            .with_title("Halo")
            .with_transparent(true)
            .with_decorations(false)
            .with_resizable(false)
            .with_window_level(WindowLevel::AlwaysOnTop)
            .with_inner_size(DEFAULT_SIZE);

        let window = event_loop.create_window(attributes)?;

        // Click-through: let mouse events fall through to whatever is beneath.
        if let Err(err) = window.set_cursor_hittest(false) {
            tracing::warn!(target: "halo::overlay", %err, "click-through unsupported on this platform");
        }

        self.anchor(&window);
        Ok(window)
    }

    /// Position the window in the configured corner of its current monitor.
    fn anchor(&self, window: &Window) {
        let Some(monitor) = window.current_monitor() else {
            tracing::warn!(target: "halo::overlay", "no monitor reported; leaving default position");
            return;
        };
        let screen = monitor.size();
        let win = window.outer_size();
        let mon_pos = monitor.position();

        let max_x = i32::try_from(screen.width.saturating_sub(win.width)).unwrap_or(0);
        let max_y = i32::try_from(screen.height.saturating_sub(win.height)).unwrap_or(0);

        let (x, y) = match self.config.position {
            Position::TopLeft => (EDGE_MARGIN, EDGE_MARGIN),
            Position::TopRight => (max_x - EDGE_MARGIN, EDGE_MARGIN),
            Position::BottomLeft => (EDGE_MARGIN, max_y - EDGE_MARGIN),
            Position::BottomRight => (max_x - EDGE_MARGIN, max_y - EDGE_MARGIN),
        };

        window.set_outer_position(PhysicalPosition::new(mon_pos.x + x, mon_pos.y + y));
    }

    fn set_visible(&mut self, visible: bool) {
        self.visible = visible;
        if let Some(window) = &self.window {
            window.set_visible(visible);
        }
        tracing::info!(target: "halo::overlay", visible, "overlay visibility toggled");
    }

    /// Drain any pending global-hotkey events and act on the toggle.
    fn poll_hotkeys(&mut self) {
        while let Ok(event) = GlobalHotKeyEvent::receiver().try_recv() {
            if event.id == self.toggle_id && event.state == global_hotkey::HotKeyState::Pressed {
                self.set_visible(!self.visible);
            }
        }
    }
}

impl ApplicationHandler for OverlayApp {
    fn resumed(&mut self, event_loop: &ActiveEventLoop) {
        if self.window.is_some() {
            return;
        }
        match self.build_window(event_loop) {
            Ok(window) => {
                tracing::info!(
                    target: "halo::overlay",
                    "Halo overlay ready (transparent · click-through · always-on-top). \
                     Toggle with Ctrl+Alt+H, quit with Esc."
                );
                self.window = Some(window);
            }
            Err(err) => {
                tracing::error!(target: "halo::overlay", %err, "failed to create overlay window");
                event_loop.exit();
            }
        }
    }

    fn window_event(
        &mut self,
        event_loop: &ActiveEventLoop,
        _window_id: WindowId,
        event: WindowEvent,
    ) {
        match event {
            WindowEvent::CloseRequested => event_loop.exit(),
            WindowEvent::KeyboardInput { event, .. }
                if event.physical_key == PhysicalKey::Code(KeyCode::Escape) =>
            {
                event_loop.exit();
            }
            _ => {}
        }
    }

    fn about_to_wait(&mut self, event_loop: &ActiveEventLoop) {
        self.poll_hotkeys();
        if self.window.is_none() {
            event_loop.exit();
        }
    }
}
