# Security Policy

## Supported versions

Halo is pre-1.0 and moves fast. Only the latest release on the `main` branch
receives security fixes until `v1.0` is tagged.

| Version | Supported |
| ------- | --------- |
| `main`  | ✅        |
| < 0.1   | ❌        |

## Reporting a vulnerability

**Please do not open a public issue for security vulnerabilities.**

Report privately through GitHub's
[security advisories](https://github.com/YohanGH/halo/security/advisories/new).
If you cannot use that channel, email the maintainer at
`yohanregnier.pro@gmail.com` with the subject line `SECURITY: halo`.

Please include:

- a description of the vulnerability and its impact,
- steps to reproduce or a proof of concept,
- affected version / commit,
- any suggested remediation.

You can expect an acknowledgement within **72 hours** and a status update
within **7 days**. Once a fix is available we will coordinate a disclosure
timeline with you and credit you in the release notes unless you prefer to
remain anonymous.

## Scope & hardening notes

Halo runs on the user's desktop with the user's own privileges and reads local
system metrics. Areas we treat as security-sensitive:

- **Configuration parsing** — untrusted `config.toml` must never allow code
  execution or path traversal.
- **Plugins** (Phase 11) — third-party widgets must run without escalating
  beyond the host process's privileges.
- **`unsafe` code** — denied by lint policy across the workspace; any exception
  must be justified in review.

The dependency tree is audited in CI on every push and weekly via
`cargo deny` (advisories, licences, banned crates and sources).
