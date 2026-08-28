#!/usr/bin/env bash
# review-gate — one entry point, three modes:
#
#   guard.sh commit   PreToolUse on `git commit *`  — refuse bypass, run checks
#   guard.sh write    PreToolUse on Edit|Write      — refuse protected paths
#   guard.sh stop     Stop                          — check before the turn ends
#
# Self-contained on purpose: a plugin runs in repos it has never seen. It reads
# hook JSON on stdin and never writes outside the cache directory.
#
# Deference rule: if the repo defines its own gate at
# .claude/scripts/preflight.sh, that script wins. The repo's definition of
# "green" beats the plugin's guess, and nothing runs twice.

set -uo pipefail

MODE="${1:-}"
ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
INPUT=""
[ -t 0 ] || INPUT="$(cat)"

have() { command -v "$1" >/dev/null 2>&1; }

# jq's `//` treats false as empty, which would invert boolean fields. Read the
# path directly and treat only null/absent as missing.
jget() {
  local path="$1" default="${2:-}" out
  { [ -z "$INPUT" ] || ! have jq; } && { printf '%s' "$default"; return 0; }
  out="$(printf '%s' "$INPUT" | jq -r "$path" 2>/dev/null)" || out=""
  { [ -z "$out" ] || [ "$out" = "null" ]; } && printf '%s' "$default" || printf '%s' "$out"
}

deny() {
  if have jq; then
    jq -n --arg r "$1" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$r}}'
    exit 0
  fi
  printf '%s\n' "$1" >&2
  exit 2
}

note() { have jq && jq -n --arg m "$1" '{systemMessage:$m,suppressOutput:true}'; exit 0; }

# --- the battery ------------------------------------------------------------

# Prints output, returns: 0 green · 1 failed · 2 nothing to run.
run_checks() {
  if [ -x "$ROOT/.claude/scripts/preflight.sh" ]; then
    "$ROOT/.claude/scripts/preflight.sh" --changed --quiet 2>&1
    return $?
  fi

  local ran=0 failed=0 out
  step() {
    local label="$1"; shift
    ran=$((ran + 1))
    if ! out="$("$@" 2>&1)"; then
      failed=$((failed + 1))
      printf '── FAIL %s\n%s\n' "$label" "$(printf '%s' "$out" | tail -n 20)"
    fi
  }

  if [ -f "$ROOT/package.json" ]; then
    local pm="npm run --silent"
    [ -f "$ROOT/yarn.lock" ] && pm="yarn"
    [ -f "$ROOT/pnpm-lock.yaml" ] && pm="pnpm run"
    [ -f "$ROOT/bun.lockb" ] && pm="bun run"
    for s in lint typecheck test; do
      if grep -qE "\"$s\"[[:space:]]*:" "$ROOT/package.json"; then
        step "$s" bash -c "cd '$ROOT' && $pm $s"
      fi
    done
  fi

  if [ -f "$ROOT/pyproject.toml" ]; then
    have ruff   && step "ruff"   bash -c "cd '$ROOT' && ruff check ."
    have pytest && step "pytest" bash -c "cd '$ROOT' && pytest -q"
  fi

  if [ -f "$ROOT/go.mod" ] && have go; then
    step "go vet"  bash -c "cd '$ROOT' && go vet ./..."
    step "go test" bash -c "cd '$ROOT' && go test ./..."
  fi

  if [ -f "$ROOT/Cargo.toml" ] && have cargo; then
    step "clippy"     bash -c "cd '$ROOT' && cargo clippy --all-targets -- -D warnings"
    step "cargo test" bash -c "cd '$ROOT' && cargo test"
  fi

  [ "$ran" -eq 0 ] && return 2
  [ "$failed" -gt 0 ] && return 1
  return 0
}

# --- modes ------------------------------------------------------------------

case "$MODE" in

  commit)
    cmd="$(jget '.tool_input.command')"
    [ -z "$cmd" ] && exit 0
    printf '%s' "$cmd" | grep -qE '(^|[;&|]|\s)git\s+(-[^ ]+\s+)*commit(\s|$)' || exit 0

    if printf '%s' "$cmd" | grep -qE '(--no-verify|(^|\s)-n(\s|$))'; then
      deny "review-gate: refused — this commit skips the quality gate (--no-verify).

If a check is wrong, fix the check or stop and say so. Do not bypass it.
Re-run without --no-verify."
    fi

    # git's own pre-commit hook already runs the battery; don't double it.
    if [ "$(git -C "$ROOT" config --get core.hooksPath 2>/dev/null)" = ".githooks" ] \
       && [ -x "$ROOT/.githooks/pre-commit" ]; then
      exit 0
    fi

    out="$(run_checks)"; status=$?
    [ $status -eq 0 ] && exit 0
    [ $status -eq 2 ] && exit 0

    deny "review-gate: commit blocked — checks failed.

$(printf '%s' "$out" | tail -n 25)

Fix the failures and commit again. Do not weaken a check or skip a test to get
past this. If the failure is pre-existing, verify that and say so before
committing on top of it."
    ;;

  write)
    file="$(jget '.tool_input.file_path')"
    [ -z "$file" ] && exit 0
    rel="${file#"$ROOT"/}"
    case "$rel" in
      .env|.env.*|*/.env|*/.env.*|*.pem|*.key|*/secrets/*|secrets/*)
        deny "review-gate: '$rel' is secret material and is never written by the agent." ;;
      */dist/*|dist/*|*/build/*|build/*|*.generated.*|*/__generated__/*)
        deny "review-gate: '$rel' is build output or generated code. Change the source or the generator and re-run it." ;;
      */node_modules/*|node_modules/*|vendor/*|*/vendor/*)
        deny "review-gate: '$rel' is installed or vendored code. Patch upstream or pin a version instead." ;;
      *.lock|*lock.json|pnpm-lock.yaml|*/pnpm-lock.yaml|yarn.lock|*/yarn.lock)
        deny "review-gate: '$rel' is a lockfile. Run the package manager rather than editing it by hand." ;;
    esac
    exit 0
    ;;

  stop)
    [ "${CLAUDE_REVIEW_GATE:-warn}" = "off" ] && exit 0
    [ "$(jget '.stop_hook_active' 'true')" = "false" ] && exit 0
    git -C "$ROOT" rev-parse --git-dir >/dev/null 2>&1 || exit 0
    [ -z "$(git -C "$ROOT" status --porcelain 2>/dev/null)" ] && exit 0

    # Report a given failing state once per session, so a turn cannot loop.
    fp="$(jget '.session_id' 'nosession')-$( { git -C "$ROOT" rev-parse HEAD; git -C "$ROOT" diff HEAD; } 2>/dev/null | { if have sha1sum; then sha1sum; else shasum; fi; } | cut -c1-12)"
    cache="${XDG_CACHE_HOME:-${TMPDIR:-/tmp}}/review-gate"
    mkdir -p "$cache" 2>/dev/null || exit 0
    [ -f "$cache/$fp" ] && exit 0

    out="$(run_checks)"; status=$?
    [ $status -ne 1 ] && exit 0
    : > "$cache/$fp"

    if [ "${CLAUDE_REVIEW_GATE:-warn}" = "block" ]; then
      printf 'review-gate: checks are failing.\n\n%s\n\nFix it, or state plainly what is failing and why you are stopping.\n' \
        "$(printf '%s' "$out" | tail -n 20)" >&2
      exit 2
    fi
    note "review-gate: checks are failing. Run /review-gate:gate-status for detail."
    ;;

  *)
    printf 'usage: guard.sh {commit|write|stop}\n' >&2
    exit 0
    ;;
esac
