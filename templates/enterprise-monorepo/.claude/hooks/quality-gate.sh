#!/usr/bin/env bash
# Stop — check the work before the turn ends.
#
# Modes (CLAUDE_QUALITY_GATE, default "warn"):
#   off    do nothing
#   warn   run the battery, show the user a note if it fails, let the turn end
#   block  exit 2 so Claude cannot stop on a red tree and must address it
#
# Loop safety: `stop_hook_active` distinguishes Stop from SubagentStop — it is
# NOT a re-entry flag. So the guard here is a marker keyed on session + working
# tree state: a given failing state blocks exactly once. If Claude changes
# nothing in response, the fingerprint is unchanged and the turn ends normally
# instead of looping forever.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

MODE="${CLAUDE_QUALITY_GATE:-warn}"
[ "$MODE" = "off" ] && exit 0

cc_in_git || exit 0

INPUT="$(cc_hook_input)"
SESSION="$(cc_json "$INPUT" '.session_id' 'nosession')"

# Only subagent stops set this to false; skip those — the parent turn is gated.
IS_STOP="$(cc_json "$INPUT" '.stop_hook_active' 'true')"
[ "$IS_STOP" = "false" ] && exit 0

# Nothing changed → nothing to gate.
[ -z "$(git -C "$CC_ROOT" status --porcelain 2>/dev/null)" ] && exit 0

FINGERPRINT="${SESSION}-$(cc_worktree_fingerprint)"
CACHE_DIR="${XDG_CACHE_HOME:-${TMPDIR:-/tmp}}/claude-quality-gate"
MARKER="$CACHE_DIR/$FINGERPRINT"
mkdir -p "$CACHE_DIR" 2>/dev/null || exit 0

# Already reported for this exact state — do not block twice on the same tree.
[ -f "$MARKER" ] && exit 0

OUT="$("$CC_ROOT/.claude/scripts/preflight.sh" --changed --quick --quiet 2>&1)"
STATUS=$?

# 0 = green, 2 = nothing configured. Neither is worth interrupting for.
[ $STATUS -eq 0 ] && exit 0
[ $STATUS -eq 2 ] && exit 0

: > "$MARKER"

FAILED="$(printf '%s' "$OUT" | grep '^PREFLIGHT_RESULT' | sed 's/.*names=//')"
DETAIL="$(printf '%s' "$OUT" | grep -v '^PREFLIGHT_RESULT' | tail -n 20)"

if [ "$MODE" = "block" ]; then
  cat >&2 <<EOF
Quality gate failed before this turn could end: ${FAILED:-see output}

$DETAIL

Address this now:
- If your change caused it, fix it.
- If it is pre-existing, verify with \`git stash\` + re-run, then say so.
- Do not weaken a check, skip a test, or bypass the gate.

If you cannot fix it, state plainly what is failing and why you are stopping.
EOF
  exit 2
fi

cc_emit_message "Quality gate: ${FAILED:-checks} failed (mode=warn). Run /preflight for detail."
exit 0
