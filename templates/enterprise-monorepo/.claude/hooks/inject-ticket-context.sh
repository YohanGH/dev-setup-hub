#!/usr/bin/env bash
# UserPromptSubmit — when a prompt names a ticket that already has a scope file,
# point Claude at it. Injects a pointer, never the file's contents: the file may
# be long, and Claude can read what it needs.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

INPUT="$(cc_hook_input)"
PROMPT="$(cc_json "$INPUT" '.prompt')"
[ -z "$PROMPT" ] && exit 0

TICKET="$(cc_extract_ticket "$PROMPT")"
[ -z "$TICKET" ] && TICKET="$(cc_branch_ticket)"
[ -z "$TICKET" ] && exit 0

DIR="$(cc_ticket_dir "$TICKET")"
[ -d "$DIR" ] || exit 0

CONTEXT="Ticket $TICKET has existing pipeline artifacts:"
for artifact in scope review report; do
  [ -f "$DIR/$artifact.md" ] && \
    CONTEXT="$CONTEXT
- .claude/tickets/$TICKET/$artifact.md"
done

# Nothing but the directory — no pointer worth injecting.
case "$CONTEXT" in *".md"*) ;; *) exit 0 ;; esac

CONTEXT="$CONTEXT

Read scope.md before changing code for this ticket, and update it rather than
diverging from it silently."

cc_emit_context "UserPromptSubmit" "$CONTEXT"
exit 0
