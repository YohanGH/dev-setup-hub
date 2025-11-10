
### SECURITY.md
```md
# Security Policy

## Supported
This repository contains configuration and scripts only. No production code is shipped here.

## Reporting a Vulnerability
If you discover a security issue (e.g., secret exposure, insecure script, or supply-chain risk):
- **Do not** open a public issue with sensitive details.
- Email: smockingart_dm@hotmail.com (or open a private security advisory on GitHub).
- We will acknowledge within 72 hours and aim for a fix or mitigation within 14 days.

## Hardening Guidelines
- Never commit secrets; use `.env` files ignored by Git and a secret manager (1Password, Vault, etc.).
- Pin versions where possible; review third-party install scripts before running.
- Prefer least-privilege permissions for any tokens used locally.

