#!/usr/bin/env bash
# preflight.sh — the local quality battery. One script, three entry points:
#
#   .claude/scripts/preflight.sh            # you, from the terminal
#   .githooks/pre-commit                    # every human commit (husky-style)
#   PreToolUse hook on `git commit`         # every Claude commit
#
# Keeping all three on one script is the point: the gate cannot drift between
# who is committing.
#
# Usage: preflight.sh [--changed|--all|--quick] [--quiet]
#   --changed  (default) checks only files changed vs the merge base
#   --all      full battery, exactly what CI runs
#   --quick    format + lint + typecheck, no tests
#
# Exit: 0 all green · 1 a check failed · 2 misconfigured (nothing to run)

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

SCOPE="${CLAUDE_PREFLIGHT_SCOPE:-changed}"
QUIET=0
RUN_TESTS=1

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     SCOPE="all" ;;
    --changed) SCOPE="changed" ;;
    --quick)   SCOPE="changed"; RUN_TESTS=0 ;;
    --quiet)   QUIET=1 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    "")        ;;
    *)         cc_warn "unknown option: $1" ;;
  esac
  shift
done

cd "$CC_ROOT" || exit 2

STEPS_RUN=0
STEPS_FAILED=0
FAILED_NAMES=""
SUMMARY=""

say() { [ "$QUIET" -eq 1 ] || printf '%s\n' "$*"; }

# run_step <label> <command...>
run_step() {
  local label="$1"; shift
  local out status
  STEPS_RUN=$((STEPS_RUN + 1))
  say "── $label"
  out="$("$@" 2>&1)"; status=$?
  if [ $status -eq 0 ]; then
    SUMMARY="${SUMMARY}  pass  ${label}\n"
  else
    STEPS_FAILED=$((STEPS_FAILED + 1))
    FAILED_NAMES="${FAILED_NAMES}${label}|"
    SUMMARY="${SUMMARY}  FAIL  ${label}\n"
    printf '%s\n' "$out" | tail -n 40 >&2
  fi
  return 0
}

run_sh() { local label="$1" cmd="$2"; run_step "$label" bash -c "$cmd"; }

# --- what changed -----------------------------------------------------------

CHANGED="$(cc_changed_files)"
if [ "$SCOPE" = "changed" ] && [ -z "$CHANGED" ]; then
  say "preflight: no changed files — nothing to check."
  printf 'PREFLIGHT_RESULT pass steps=0 failed=0\n'
  exit 0
fi

filter_ext() { printf '%s\n' "$CHANGED" | grep -E "$1" || true; }

# --- Node / TypeScript ------------------------------------------------------

if [ -f "$CC_ROOT/package.json" ]; then
  PM="$(cc_detect_pm)"
  say "preflight: node project (${PM}), scope=${SCOPE}"

  JS_FILES="$(filter_ext '\.(ts|tsx|js|jsx|mjs|cjs|vue|svelte)$')"

  if cc_has_script "format:check"; then
    run_sh "format" "$(cc_run_script format:check)"
  elif cc_has_script "format"; then
    run_sh "format" "$(cc_run_script format) --check"
  fi

  if cc_has_script "lint"; then
    if [ "$SCOPE" = "changed" ] && [ -n "$JS_FILES" ]; then
      run_sh "lint (changed)" "$(cc_run_script lint) -- $(printf '%s' "$JS_FILES" | tr '\n' ' ')"
    else
      run_sh "lint" "$(cc_run_script lint)"
    fi
  fi

  # Typecheck is always whole-project: a change in one file breaks another.
  if cc_has_script "typecheck"; then
    run_sh "typecheck" "$(cc_run_script typecheck)"
  elif [ -f "$CC_ROOT/tsconfig.json" ] && cc_have npx; then
    run_sh "typecheck" "npx --no-install tsc --noEmit"
  fi

  if [ "$RUN_TESTS" -eq 1 ] && cc_has_script "test"; then
    if [ "$SCOPE" = "changed" ] && [ -n "$JS_FILES" ]; then
      run_sh "tests (related)" "$(cc_run_script test) -- --passWithNoTests --findRelatedTests $(printf '%s' "$JS_FILES" | tr '\n' ' ')"
    else
      run_sh "tests" "$(cc_run_script test)"
    fi
  fi
fi

# --- Python -----------------------------------------------------------------

if [ -f "$CC_ROOT/pyproject.toml" ] || [ -f "$CC_ROOT/setup.cfg" ]; then
  say "preflight: python project, scope=${SCOPE}"
  PY_FILES="$(filter_ext '\.py$' | tr '\n' ' ')"

  if cc_have ruff; then
    run_sh "format (ruff)" "ruff format --check ${PY_FILES:-.}"
    run_sh "lint (ruff)"   "ruff check ${PY_FILES:-.}"
  elif cc_have black; then
    run_sh "format (black)" "black --check ${PY_FILES:-.}"
  fi

  cc_have mypy && run_sh "typecheck (mypy)" "mypy ${PY_FILES:-.}"

  if [ "$RUN_TESTS" -eq 1 ] && cc_have pytest; then
    run_sh "tests (pytest)" "pytest -q"
  fi
fi

# --- Go ---------------------------------------------------------------------

if [ -f "$CC_ROOT/go.mod" ] && cc_have go; then
  say "preflight: go project, scope=${SCOPE}"
  run_sh "format (gofmt)" 'test -z "$(gofmt -l .)"'
  run_sh "vet"            "go vet ./..."
  [ "$RUN_TESTS" -eq 1 ] && run_sh "tests" "go test ./..."
fi

# --- Rust -------------------------------------------------------------------

if [ -f "$CC_ROOT/Cargo.toml" ] && cc_have cargo; then
  say "preflight: rust project, scope=${SCOPE}"
  run_sh "format (fmt)" "cargo fmt --check"
  run_sh "lint (clippy)" "cargo clippy --all-targets -- -D warnings"
  [ "$RUN_TESTS" -eq 1 ] && run_sh "tests" "cargo test"
fi

# --- Makefile fallback ------------------------------------------------------

if [ "$STEPS_RUN" -eq 0 ] && [ -f "$CC_ROOT/Makefile" ]; then
  say "preflight: Makefile fallback"
  for target in lint typecheck test; do
    if grep -qE "^${target}:" "$CC_ROOT/Makefile"; then
      [ "$target" = "test" ] && [ "$RUN_TESTS" -eq 0 ] && continue
      run_sh "$target" "make $target"
    fi
  done
fi

# --- Secret scan (always) ---------------------------------------------------

if [ -n "$CHANGED" ]; then
  SECRET_HITS="$("$SCRIPT_DIR/scan-secrets.sh" 2>/dev/null)"
  STEPS_RUN=$((STEPS_RUN + 1))
  if [ -z "$SECRET_HITS" ]; then
    SUMMARY="${SUMMARY}  pass  secret scan\n"
  else
    STEPS_FAILED=$((STEPS_FAILED + 1))
    FAILED_NAMES="${FAILED_NAMES}secret scan|"
    SUMMARY="${SUMMARY}  FAIL  secret scan\n"
    printf '%s\n' "$SECRET_HITS" >&2
  fi
fi

# --- Report -----------------------------------------------------------------

if [ "$STEPS_RUN" -eq 0 ]; then
  cc_warn "preflight ran no checks — no known stack detected at $CC_ROOT."
  cc_warn "Add the commands for this repo to .claude/scripts/preflight.sh."
  printf 'PREFLIGHT_RESULT unconfigured steps=0 failed=0\n'
  exit 2
fi

say ""
say "preflight — ${STEPS_RUN} check(s), ${STEPS_FAILED} failed"
[ "$QUIET" -eq 1 ] || printf "%b" "$SUMMARY"

if [ "$STEPS_FAILED" -gt 0 ]; then
  printf 'PREFLIGHT_RESULT fail steps=%s failed=%s names=%s\n' \
    "$STEPS_RUN" "$STEPS_FAILED" "$(printf '%s' "$FAILED_NAMES" | sed 's/|$//; s/|/, /g')"
  exit 1
fi

printf 'PREFLIGHT_RESULT pass steps=%s failed=0\n' "$STEPS_RUN"
exit 0
