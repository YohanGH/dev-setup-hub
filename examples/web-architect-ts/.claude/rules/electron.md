---
paths:
  - "apps/desktop/**/*.ts"
---

# Electron desktop (cross-platform)

Loads only for the desktop app. Ships on Windows, macOS, and Linux.

## Security (non-negotiable)

- `contextIsolation: true`, `nodeIntegration: false`. The renderer never gets
  raw Node access.
- Expose a **typed, minimal API via `contextBridge`** in the preload; the renderer
  talks to the main process only through those channels — no ad-hoc `ipcRenderer`
  everywhere.
- Validate every IPC payload in the main process as if it were untrusted.

## Cross-platform behavior

- Use `app.getPath(...)` for user data / cache / logs — never hardcoded paths.
- Account for platform differences: menu roles, the macOS `window-all-closed`
  behavior, tray vs. dock, and frameless/traffic-light quirks.
- File dialogs and shell integration go through Electron APIs (`dialog`,
  `shell`), which handle per-OS conventions.

## Packaging

- Build targets: NSIS/`.exe` (Windows), `.dmg` (macOS), `AppImage`/`.deb` (Linux).
- Keep signing/notarization config out of source; reference env vars.
- Reuse the Quasar frontend — don't fork UI for desktop; guard any desktop-only path.
