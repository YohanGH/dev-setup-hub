# Security conventions

## Secrets

- **No secret ever enters the repo.** Not in code, tests, fixtures, snapshots,
  commit messages, or a `.md` file.
- `.env*`, `*.pem`, `*.key`, `secrets/**` are in `permissions.deny` — Claude
  cannot read them, and that is intentional. Do not work around it by asking for
  the values to be pasted into the chat.
- Config comes from the environment, is validated at boot, and the app refuses to
  start on a missing required variable. Fail loudly at startup, not lazily at
  first use.
- `.env.example` lists every variable with a **dummy** value and a comment.
- A leaked secret is rotated first, removed from history second.

## Input and output

- Validate every external input at the boundary: HTTP body, query, headers,
  webhook payloads, queue messages, file uploads, CLI args.
- Allowlist, don't blocklist.
- Parameterized queries only. String-concatenated SQL is a blocking review defect,
  including in scripts and migrations.
- Escape on output according to the sink (HTML, shell, SQL, log). Never build a
  shell command from user input — use argument arrays.
- Path handling: resolve and verify the result stays inside the intended root
  before touching the filesystem.

## AuthN / AuthZ

- Authentication at the edge; **authorization at the resource**, checked in the
  handler that owns the data.
- Deny by default. A new endpoint is unreachable until its rule is declared.
- Never trust a client-supplied identifier for ownership — resolve the owner
  server-side from the session.
- Return `404` rather than `403` when the existence of the resource is itself
  privileged information.

## Logging and telemetry

- Never log: credentials, tokens, full card numbers, personal data, request
  bodies of authenticated users, or full stack traces to a user-facing channel.
- Log structured events with a `traceId`; redact by allowlist of fields.
- Error responses carry `traceId` so support can correlate without the payload.

## Dependencies and supply chain

- Lockfile committed; installs are reproducible (`<CI_INSTALL_CMD>`).
- A new dependency needs a justification in the PR: what it does, why not the
  standard library, its maintenance status.
- Automated advisory scan runs in CI and blocks on `high`/`critical`.
- Never `curl | sh` in a script that a developer or CI runs.

## For Claude specifically

- If a task appears to require reading a denied path, stop and say so rather
  than finding another route to the content.
- Never disable a security control (validation, authz check, CSP, TLS
  verification) to make something work — report the blocker instead.
- Flag, don't fix silently: if you notice a vulnerability outside the ticket's
  scope, report it in the ticket report and let a human triage it.
- `/security-review` is available for a focused pass on the pending diff.
