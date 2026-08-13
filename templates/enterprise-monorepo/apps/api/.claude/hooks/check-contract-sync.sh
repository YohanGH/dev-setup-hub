#!/usr/bin/env bash
# Package-scoped hook (apps/api) — PostToolUse on Edit|Write.
#
# The API's request/response schemas generate the types that apps/web imports.
# Editing a schema without regenerating leaves the frontend compiling against a
# contract the backend no longer honours — and nothing fails until runtime.
#
# This warns; it does not block. Regeneration is a build step the developer runs,
# and a hook that blocks on it would fire mid-edit, before the work is finished.
#
# Scope note: this only runs for sessions started in apps/api/, because it is
# wired in apps/api/.claude/settings.json and project settings load from the
# starting directory only.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../../../../.claude/scripts/lib/common.sh
. "$SCRIPT_DIR/../../../../.claude/scripts/lib/common.sh" 2>/dev/null || exit 0

INPUT="$(cc_hook_input)"
FILE="$(cc_json "$INPUT" '.tool_input.file_path')"
[ -z "$FILE" ] && exit 0

case "$FILE" in
  */apps/api/src/schemas/*) ;;
  *) exit 0 ;;
esac

GENERATED="$CC_ROOT/packages/shared/src/generated"
[ -d "$GENERATED" ] || exit 0

# Newest schema vs newest generated artifact.
newest() { find "$1" -type f -printf '%T@\n' 2>/dev/null | sort -rn | head -n1; }
SCHEMA_T="$(newest "$CC_ROOT/apps/api/src/schemas")"
GEN_T="$(newest "$GENERATED")"

[ -z "$SCHEMA_T" ] || [ -z "$GEN_T" ] && exit 0

if awk -v a="$SCHEMA_T" -v b="$GEN_T" 'BEGIN{exit !(a>b)}'; then
  cc_emit_message "apps/api: schemas changed after the last type generation — run the generate step before committing, or apps/web will compile against a stale contract."
fi

exit 0
