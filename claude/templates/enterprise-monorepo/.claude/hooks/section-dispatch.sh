#!/usr/bin/env bash
# PreToolUse (Edit|Write|MultiEdit) — per-section architectural boundaries.
#
# WHY THIS EXISTS
#
# There are three ways to scope behaviour to a section of the repo, and they do
# not have the same reach:
#
#   1. Per-package .claude/settings.json hooks — only fire when Claude is
#      STARTED in that package. Inert from the repo root.
#   2. Skill frontmatter `hooks:` — only fire while that skill is active. Great
#      for advisory tooling, useless as a hard boundary (the skill may not load).
#   3. This: one hook, registered once at the root, that dispatches on the
#      edited file's path. Works from anywhere, whatever is loaded.
#
# Hard architectural rules — "routes must not import the database" — belong
# here, because they must hold even in the session that never loaded the skill
# explaining them. Advisory tooling belongs in (1) or (2), where it costs
# nothing when out of scope.
#
# Policy lives in .claude/sections.json so this script never changes.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

[ "${CLAUDE_SECTION_RULES:-on}" = "off" ] && exit 0

CONFIG="$CC_ROOT/.claude/sections.json"
[ -f "$CONFIG" ] || exit 0
cc_have jq || exit 0

INPUT="$(cc_hook_input)"
FILE="$(cc_json "$INPUT" '.tool_input.file_path')"
[ -z "$FILE" ] && exit 0

REL="${FILE#"$CC_ROOT"/}"

# The content being written. Write carries `content`; Edit carries `new_string`;
# MultiEdit carries a list of edits. Concatenate whatever is present — we only
# ever pattern-match, so extra context is harmless.
CONTENT="$(printf '%s' "$INPUT" | jq -r '
  [ .tool_input.content?,
    .tool_input.new_string?,
    ( .tool_input.edits? // [] | .[]?.new_string? )
  ] | map(select(. != null)) | join("\n")
' 2>/dev/null)"
[ -z "$CONTENT" ] && exit 0

# Strip comment lines before matching, so documentation of a rule never trips it.
CONTENT="$(printf '%s' "$CONTENT" | grep -vE '^\s*(//|#|\*|/\*)' || true)"
[ -z "$CONTENT" ] && exit 0

SECTION_COUNT="$(jq -r '.sections | length' "$CONFIG" 2>/dev/null || echo 0)"
i=0
while [ "$i" -lt "$SECTION_COUNT" ]; do
  MATCH="$(jq -r ".sections[$i].match" "$CONFIG")"
  case "$REL" in
    *"$MATCH"*)
      NAME="$(jq -r ".sections[$i].name" "$CONFIG")"
      SKILL="$(jq -r ".sections[$i].skill // empty" "$CONFIG")"
      RULE_COUNT="$(jq -r ".sections[$i].forbid | length" "$CONFIG")"
      j=0
      while [ "$j" -lt "$RULE_COUNT" ]; do
        PATTERN="$(jq -r ".sections[$i].forbid[$j].pattern" "$CONFIG")"
        if printf '%s' "$CONTENT" | grep -qE "$PATTERN"; then
          MESSAGE="$(jq -r ".sections[$i].forbid[$j].message" "$CONFIG")"
          HINT=""
          [ -n "$SKILL" ] && HINT="

The \`$SKILL\` skill for this section explains the pattern to use instead."
          cc_emit_deny "PreToolUse" \
"Section boundary violated in \`$NAME\` (\`$REL\`).

$MESSAGE$HINT

If this rule is genuinely wrong for this file, say so and stop — do not work
around it. The rule lives in .claude/sections.json and changing it is a
reviewed decision."
          exit 0
        fi
        j=$((j + 1))
      done
      # First matching section wins; nested sections are ordered most-specific first.
      exit 0
      ;;
  esac
  i=$((i + 1))
done

exit 0
