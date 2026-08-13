---
name: core-boundaries
description: Change bootstrap, configuration, dependency wiring, logging or error plumbing in apps/api/src/core. Use when editing app startup, the DI container, config loading, middleware, or the error mapper.
allowed-tools: Read Grep Glob Edit Write
---

# Core

Loads only while working in `apps/api/src/core/`. Small directory, outsized
blast radius: **everything imports core, so core imports nothing of the domain.**

## What lives here

| File | Owns |
|------|------|
| `bootstrap.ts` | Composition root — builds the object graph, starts the server |
| `config.ts` | Reads and **validates** the environment once, at boot |
| `errors.ts` | The domain error base types and the HTTP mapping table |
| `logger.ts` | Structured logging with `traceId` |
| `middleware/` | Cross-cutting request concerns |

## Rules

- **Config is validated at boot and the process refuses to start on a missing
  required variable.** Fail loudly on startup, never lazily on the first
  request at 3am. `process.env` is read *here and nowhere else*; everything
  downstream receives typed config.
- **No domain imports.** `core` must not import from `../services` or
  `../routes`. If it needs to, the dependency is inverted — define the interface
  in core, implement it in the domain.
- **One error-mapping table**, in `errors.ts`. Adding a domain error means
  adding a row here, not a `try/catch` in a handler.
- Middleware order is load-bearing and non-obvious: keep the list commented with
  *why* each sits where it does. This is the file where a wrong reorder causes
  an authorization bypass.
- Nothing here does I/O at module load. Import time must stay free of side
  effects, or tests and scripts pay for the whole app.

## Before changing anything here

A change in `core` reaches every route and every service. Run
`@impact-scout <symbol>` first — this is exactly the case it exists for. Then
state the blast radius in the scope file.

Adding a required environment variable is a **breaking change for every
environment** that does not have it yet. Default it, or stage it: add optional,
deploy, set everywhere, then make it required.
