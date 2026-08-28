---
description: CI, container and infrastructure rules — loaded when touching pipeline or infra files
paths:
  - ".github/**"
  - ".gitlab-ci.yml"
  - "**/Dockerfile"
  - "**/docker-compose*.yml"
  - "**/*.tf"
  - "**/k8s/**"
  - "**/helm/**"
---

# CI & infrastructure

- **Reproducible installs only**: the lockfile-respecting install command
  (`<CI_INSTALL_CMD>`), never a loose install that can resolve new versions.
- Pin actions/images by digest or exact version, never a floating tag like
  `latest` or `@main`.
- **No secret in a pipeline file.** Secrets come from the platform's secret
  store and are referenced, never inlined — including in `echo` for debugging.
- Never `curl | sh`. Download, verify, then execute.
- CI runs the same battery as local: `.claude/scripts/preflight.sh --all`. If CI
  and the local gate diverge, fix the script, not the pipeline.
- Jobs are idempotent and safe to re-run. No step that only works the first time.
- Containers: non-root user, minimal base, no build toolchain in the runtime
  layer, `.dockerignore` covering `node_modules`, `.git`, `.env*`.
- Infrastructure changes are `plan`-reviewed before apply; a plan showing an
  unexpected destroy is a stop-and-ask, always.

Claude does not trigger deployments, apply infrastructure, or rotate secrets.
Propose the change; a human runs it.
