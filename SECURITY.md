# Security Policy

## Supported Versions

This repository is a documentation and configuration knowledge base rather than
a versioned software product. Security-relevant fixes are always applied to the
latest state of the `main` branch.

| Version | Supported          |
| ------- | ------------------ |
| `main`  | :white_check_mark: |

## Reporting a Vulnerability

We take security seriously. If you discover a vulnerability — for example a
configuration example that leaks secrets, an insecure hook, or a command that
could cause harm — please report it responsibly.

**Please do not open a public issue for security problems.**

Instead:

1. Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability)
   ("Report a vulnerability" in the **Security** tab), or
2. Contact the maintainer privately through their GitHub profile
   [@YohanGH](https://github.com/YohanGH).

When reporting, please include:

- A description of the issue and its potential impact.
- Steps to reproduce or a proof of concept.
- Any suggested remediation, if you have one.

## What to expect

- **Acknowledgement** of your report as soon as reasonably possible.
- An assessment of the issue and, if confirmed, a fix on `main`.
- Credit for the discovery, unless you prefer to remain anonymous.

## Scope & good practice

Because this repo shares example Claude Code configurations, keep in mind:

- **Never commit real secrets** (API keys, tokens, `.env` files). Use
  placeholders like `<YOUR_API_KEY>`.
- **Review hooks and commands** before running them — they can execute shell
  commands on your machine.
- Treat any configuration copied from here as a starting point to audit, not a
  black box to run blindly.

Thank you for helping keep this project and its users safe.
