#!/usr/bin/env bash
# PreToolUse (Bash, `git commit *`) — the husky equivalent for Claude.
#
# Two jobs:
#   1. Refuse --no-verify outright. That flag exists to skip the gate.
#   2. Run the same preflight the git hook runs, and deny the commit if it fails.
#
# When .githooks/ is installed, git will run preflight itself, so this hook only
# guards the bypass flags — the battery is not run twice. Force it with
# CLAUDE_PRECOMMIT_GATE=always; disable entirely with =off.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

MODE="${CLAUDE_PRECOMMIT_GATE:-auto}"
[ "$MODE" = "off" ] && exit 0

INPUT="$(cc_hook_input)"
COMMAND="$(cc_json "$INPUT" '.tool_input.command')"
[ -z "$COMMAND" ] && exit 0

# Only act on an actual commit. `git log --grep="commit"` must pass through.
printf '%s' "$COMMAND" | grep -qE '(^|[;&|]|\s)git\s+(-[^ ]+\s+)*commit(\s|$)' || exit 0

# --- 1. bypass flags --------------------------------------------------------

if printf '%s' "$COMMAND" | grep -qE '(--no-verify|(^|\s)-n(\s|$))'; then
  cc_emit_deny "PreToolUse" \
"Refused: this commit skips the quality gate (--no-verify).

The gate is the project's contract — see .claude/conventions/git.md. If a check
is wrong, fix the check or say so and stop; do not bypass it.

Re-run the commit without --no-verify."
  exit 0
fi

# --- 2. the battery ---------------------------------------------------------

HOOKS_PATH="$(git -C "$CC_ROOT" config --get core.hooksPath 2>/dev/null || true)"
if [ "$MODE" != "always" ] && [ "$HOOKS_PATH" = ".githooks" ] && [ -x "$CC_ROOT/.githooks/pre-commit" ]; then
  # git runs the same script on its own; running it here as well would double
  # the wait for no extra safety.
  exit 0
fi

OUT="$("$CC_ROOT/.claude/scripts/preflight.sh" --changed --quiet 2>&1)"
STATUS=$?

case $STATUS in
  0) exit 0 ;;
  2)
    # Nothing detected to run. Don't block on a misconfiguration.
    cc_emit_message "preflight ran no checks — the commit was not gated."
    exit 0
    ;;
esac

FAILED="$(printf '%s' "$OUT" | grep '^PREFLIGHT_RESULT' | sed 's/.*names=//')"
DETAIL="$(printf '%s' "$OUT" | grep -v '^PREFLIGHT_RESULT' | tail -n 25)"

cc_emit_deny "PreToolUse" \
"Commit blocked — preflight failed: ${FAILED:-see output}

$DETAIL

Fix the failures and commit again. Do not weaken a check, skip a test, or add
--no-verify to get past this. If the failure is pre-existing and unrelated to
your change, say so and ask before committing on top of it."
exit 0
