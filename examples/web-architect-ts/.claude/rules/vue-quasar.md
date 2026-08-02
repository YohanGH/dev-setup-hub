---
paths:
  - "apps/web/**/*.{ts,vue}"
  - "packages/**/*.vue"
---

# Vue 3 + Quasar (frontend)

Loads only for frontend files.

- **Composition API + `<script setup lang="ts">`** for new components. Type props
  with `defineProps<T>()` and emits with `defineEmits<T>()`.
- Use **Quasar components** (`q-*`) and its plugins (`Notify`, `Dialog`) rather
  than reinventing UI or pulling a second UI lib.
- Keep state in **Pinia** stores, typed; components stay thin.
- **Never call `fetch`/`axios` directly in components** — go through the typed API
  client that wraps the REST endpoints and returns shared `packages/` types.
- Reuse DTO/response types from `packages/` so the front and the NestJS API can't
  drift.
- Quasar spans web **and** the Electron desktop build: don't use browser-only APIs
  (`window.location`, direct `localStorage` assumptions) without a guard — the same
  component may render inside Electron.
