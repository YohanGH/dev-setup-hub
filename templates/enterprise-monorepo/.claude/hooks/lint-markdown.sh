#!/usr/bin/env bash
# Skill-scoped hook — declared in the `hooks:` frontmatter of the `docs-format`
# skill, so it runs ONLY while that skill is active.
#
# That is the point: a markdown linter is worth having while writing docs and
# pure overhead during every other edit in the repo. Wiring it in settings.json
# would run it on every session; wiring it to the skill costs nothing until
# someone is actually writing documentation.
#
# Advisory only — it never blocks, and it exits 0 when no linter is installed.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

INPUT="$(cc_hook_input)"
FILE="$(cc_json "$INPUT" '.tool_input.file_path')"
[ -z "$FILE" ] && FILE="${CLAUDE_FILE_PATHS:-}"
[ -z "$FILE" ] && exit 0

FINDINGS=""

for f in $FILE; do
  case "$f" in *.md|*.mdx) ;; *) continue ;; esac
  [ -f "$f" ] || continue

  if [ -x "$CC_ROOT/node_modules/.bin/markdownlint" ]; then
    out="$("$CC_ROOT/node_modules/.bin/markdownlint" "$f" 2>&1 | head -n 10)"
    [ -n "$out" ] && FINDINGS="${FINDINGS}${out}"$'\n'
    continue
  fi

  # No linter installed — check the two things that actually mislead a reader.
  long="$(awk 'length > 100 && !/^\s*[|`]/ {print FILENAME":"NR": line over 100 chars"}' "$f" | head -n 3)"
  [ -n "$long" ] && FINDINGS="${FINDINGS}${long}"$'\n'

  # A fenced block opened and never closed swallows the rest of the document.
  fences="$(grep -c '^```' "$f" 2>/dev/null || echo 0)"
  if [ $((fences % 2)) -ne 0 ]; then
    FINDINGS="${FINDINGS}${f}: unclosed code fence — everything after it renders as code"$'\n'
  fi
done

[ -z "$FINDINGS" ] && exit 0

cc_emit_message "markdown: $(printf '%s' "$FINDINGS" | head -n 4 | tr '\n' ' ')"
exit 0
