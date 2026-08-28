#!/usr/bin/env bash
# checks.sh — the one quality battery for this repo.
#
# Three callers, one script, so the gate cannot drift between who is committing:
#
#   .claude/scripts/checks.sh          you, from the terminal
#   .githooks/pre-commit               every human commit
#   phase 06 of the spec pipeline      every Claude commit
#
# Usage: checks.sh [--all|--quick] [--quiet]
#   --all     (default) format, lint, typecheck, tests
#   --quick   everything except tests
#   --quiet   only the summary and the failures
#
# Exit: 0 all green · 1 a check failed · 2 not configured
#
# ---------------------------------------------------------------------------
# CONFIGURE — `/spec-init` writes these four lines by detecting the stack.
# Edit them by hand for anything it got wrong. An empty command is skipped and
# reported as skipped, never as passing.
# ---------------------------------------------------------------------------

FORMAT_CMD=""
LINT_CMD=""
TYPECHECK_CMD=""
TEST_CMD=""

# ---------------------------------------------------------------------------

set -u

RUN_TESTS=1
QUIET=0

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     RUN_TESTS=1 ;;
    --quick)   RUN_TESTS=0 ;;
    --quiet)   QUIET=1 ;;
    -h|--help) sed -n '2,18p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "")        ;;
    *)         printf 'checks: unknown option: %s\n' "$1" >&2 ;;
  esac
  shift
done

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$ROOT" || exit 2

say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }

RUN=0
FAILED=0
SKIPPED=0
SUMMARY=""

# run_step <label> <command string>
run_step() {
  label="$1"
  cmd="$2"

  if [ -z "$cmd" ]; then
    SKIPPED=$((SKIPPED + 1))
    SUMMARY="${SUMMARY}  skip  ${label}  (no command configured)
"
    return 0
  fi

  RUN=$((RUN + 1))
  say "── ${label}: ${cmd}"

  if out="$(bash -c "$cmd" 2>&1)"; then
    SUMMARY="${SUMMARY}  pass  ${label}
"
  else
    FAILED=$((FAILED + 1))
    SUMMARY="${SUMMARY}  FAIL  ${label}
"
    printf '%s\n' "$out" | tail -n 40 >&2
  fi
  return 0
}

if [ -z "${FORMAT_CMD}${LINT_CMD}${TYPECHECK_CMD}${TEST_CMD}" ]; then
  printf 'checks: not configured — run /spec-init, or fill the CONFIGURE block in %s\n' "$0" >&2
  printf 'CHECKS_RESULT unconfigured run=0 failed=0 skipped=4\n'
  exit 2
fi

run_step format    "$FORMAT_CMD"
run_step lint      "$LINT_CMD"
run_step typecheck "$TYPECHECK_CMD"
[ "$RUN_TESTS" -eq 1 ] && run_step tests "$TEST_CMD"

say ""
say "── summary"
printf '%s' "$SUMMARY"

if [ "$FAILED" -gt 0 ]; then
  printf 'CHECKS_RESULT fail run=%s failed=%s skipped=%s\n' "$RUN" "$FAILED" "$SKIPPED"
  exit 1
fi

printf 'CHECKS_RESULT pass run=%s failed=%s skipped=%s\n' "$RUN" "$FAILED" "$SKIPPED"
exit 0
