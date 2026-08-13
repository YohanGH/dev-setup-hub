#!/usr/bin/env bash
# PostToolUse (Bash, `git commit *`) — append the commit to the ticket's log.
#
# This is what makes the pipeline auditable: at report time, the log is a record
# of what was actually committed, written by the tool rather than remembered by
# the model. Runs async; never blocks, never fails a turn.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

INPUT="$(cc_hook_input)"

# Only log commits that actually succeeded.
EXIT_CODE="$(cc_json "$INPUT" '.tool_output.exit_code' "0")"
[ "$EXIT_CODE" != "0" ] && exit 0

cc_in_git || exit 0

SHA="$(git -C "$CC_ROOT" rev-parse --short HEAD 2>/dev/null)" || exit 0
SUBJECT="$(git -C "$CC_ROOT" log -1 --pretty=%s 2>/dev/null)"
STATS="$(git -C "$CC_ROOT" show --stat --oneline HEAD 2>/dev/null | tail -n1 | sed 's/^ *//')"

# Ticket from the commit message first, then the branch.
TICKET="$(cc_extract_ticket "$(git -C "$CC_ROOT" log -1 --pretty=%B 2>/dev/null)")"
[ -z "$TICKET" ] && TICKET="$(cc_branch_ticket)"
[ -z "$TICKET" ] && exit 0

DIR="$(cc_ticket_dir "$TICKET")"
mkdir -p "$DIR" 2>/dev/null || exit 0

printf '%s  %s  %s  [%s]\n' \
  "$(date '+%Y-%m-%d %H:%M')" "$SHA" "$SUBJECT" "${STATS:-no stats}" \
  >> "$DIR/commits.log"

exit 0
