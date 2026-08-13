#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit) — format the file that was just written.
#
# Runs async: it must never slow a turn down and must never fail one. Every
# formatter here is invoked only if it is already installed locally — this hook
# never installs anything and never reaches the network.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

INPUT="$(cc_hook_input)"
FILE="$(cc_json "$INPUT" '.tool_input.file_path')"

# Fall back to the environment variable form when jq is unavailable.
[ -z "$FILE" ] && FILE="${CLAUDE_FILE_PATHS:-}"
[ -z "$FILE" ] && exit 0

for f in $FILE; do
  [ -f "$f" ] || continue
  case "$f" in
    */node_modules/*|*/dist/*|*/build/*|*/vendor/*) continue ;;
  esac

  case "$f" in
    *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.vue|*.svelte|*.json|*.css|*.scss|*.html|*.md|*.yml|*.yaml)
      if [ -x "$CC_ROOT/node_modules/.bin/prettier" ]; then
        "$CC_ROOT/node_modules/.bin/prettier" --write --ignore-unknown "$f" >/dev/null 2>&1
      fi
      ;;
    *.py)
      if cc_have ruff; then
        ruff format "$f" >/dev/null 2>&1
        ruff check --fix-only "$f" >/dev/null 2>&1
      elif cc_have black; then
        black -q "$f" >/dev/null 2>&1
      fi
      ;;
    *.go)  cc_have gofmt && gofmt -w "$f" >/dev/null 2>&1 ;;
    *.rs)  cc_have rustfmt && rustfmt --edition 2021 "$f" >/dev/null 2>&1 ;;
    *.sh)  cc_have shfmt && shfmt -w -i 2 "$f" >/dev/null 2>&1 ;;
  esac
done

exit 0
