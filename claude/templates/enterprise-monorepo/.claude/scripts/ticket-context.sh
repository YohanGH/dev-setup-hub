#!/usr/bin/env bash
# ticket-context.sh <TICKET-ID> — resolve everything known about a ticket.
#
# Resolution order (first hit wins for the ticket body):
#   1. .claude/tickets/<ID>/ticket.md   — pasted or cached locally
#   2. gh issue view                    — when the id is numeric or #-prefixed
#   3. gh search                        — when the id is a key like PROJ-1234
#
# Always prints the pipeline state (scope / review / report) if it exists.
# Exit: 0 something was found · 1 nothing was found (caller must ask a human).

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

TICKET="${1:-}"
if [ -z "$TICKET" ]; then
  TICKET="$(cc_branch_ticket)"
  [ -n "$TICKET" ] && cc_log "no id given — using '$TICKET' from the branch name"
fi

if [ -z "$TICKET" ]; then
  cc_err "usage: ticket-context.sh <TICKET-ID>   (none could be inferred from the branch)"
  exit 1
fi

DIR="$(cc_ticket_dir "$TICKET")"
SOURCE="${CLAUDE_TICKET_SOURCE:-gh}"
FOUND=1

printf '# Ticket context: %s\n\n' "$TICKET"

# --- body -------------------------------------------------------------------

if [ -f "$DIR/ticket.md" ]; then
  printf '## Ticket (local: .claude/tickets/%s/ticket.md)\n\n' "$TICKET"
  cat "$DIR/ticket.md"
  printf '\n'
  FOUND=0
elif [ "$SOURCE" = "gh" ] && cc_have gh; then
  NUM="$(printf '%s' "$TICKET" | grep -oE '[0-9]+$' || true)"
  BODY=""
  if printf '%s' "$TICKET" | grep -qE '^#?[0-9]+$'; then
    BODY="$(gh issue view "${TICKET#\#}" --json number,title,body,labels,state,url \
              --template '## {{.title}} (#{{.number}}, {{.state}}){{"\n"}}{{.url}}{{"\n\n"}}{{.body}}{{"\n"}}' 2>/dev/null)"
  elif [ -n "$NUM" ]; then
    BODY="$(gh issue view "$NUM" --json number,title,body,labels,state,url \
              --template '## {{.title}} (#{{.number}}, {{.state}}){{"\n"}}{{.url}}{{"\n\n"}}{{.body}}{{"\n"}}' 2>/dev/null)"
    if [ -z "$BODY" ]; then
      BODY="$(gh search issues "$TICKET" --limit 3 --json number,title,url \
                --template '{{range .}}- #{{.number}} {{.title}} — {{.url}}{{"\n"}}{{end}}' 2>/dev/null)"
      [ -n "$BODY" ] && BODY="## Possible matches (not confirmed)"$'\n\n'"$BODY"
    fi
  fi
  if [ -n "$BODY" ]; then
    printf '## Ticket (gh)\n\n%s\n' "$BODY"
    FOUND=0
  fi
fi

if [ "$FOUND" -ne 0 ]; then
  printf '## Ticket\n\nNOT FOUND.\n\n'
  printf 'No `.claude/tickets/%s/ticket.md` and nothing resolvable via `gh`.\n' "$TICKET"
  printf 'Ask the user to paste the ticket, then save it to that path before scoping.\n\n'
fi

# --- pipeline state ---------------------------------------------------------

printf '## Pipeline state\n\n'
for artifact in scope review report; do
  if [ -f "$DIR/$artifact.md" ]; then
    printf -- '- `%s.md`: present (%s lines, modified %s)\n' \
      "$artifact" \
      "$(wc -l < "$DIR/$artifact.md" | tr -d ' ')" \
      "$(date -r "$DIR/$artifact.md" '+%Y-%m-%d %H:%M' 2>/dev/null || echo 'unknown')"
  else
    printf -- '- `%s.md`: absent\n' "$artifact"
  fi
done

# --- repo state -------------------------------------------------------------

if cc_in_git; then
  printf '\n## Repo state\n\n'
  printf -- '- branch: `%s`\n' "$(cc_current_branch)"
  printf -- '- base: `%s` (merge-base `%s`)\n' "$(cc_default_branch)" "$(cc_merge_base | cut -c1-8)"
  CHANGED_COUNT="$(cc_changed_files | wc -l | tr -d ' ')"
  printf -- '- changed files vs base: %s\n' "$CHANGED_COUNT"

  RELATED="$(git -C "$CC_ROOT" log --oneline --all --grep="$TICKET" -n 5 2>/dev/null)"
  if [ -n "$RELATED" ]; then
    printf -- '- commits mentioning %s:\n' "$TICKET"
    printf '%s\n' "$RELATED" | sed 's/^/    /'
  fi
fi

exit "$FOUND"
