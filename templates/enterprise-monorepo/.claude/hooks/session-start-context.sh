#!/usr/bin/env bash
# SessionStart — stdout is injected into Claude's context before your first
# prompt. It is paid on every session, so it stays short and factual: state
# Claude cannot derive cheaply, never advice it already has in CLAUDE.md.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=../scripts/lib/common.sh
. "$SCRIPT_DIR/../scripts/lib/common.sh"

cc_in_git || exit 0

BRANCH="$(cc_current_branch)"
TICKET="$(cc_branch_ticket)"
DIRTY="$(git -C "$CC_ROOT" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
BASE="$(cc_default_branch)"
AHEAD="$(git -C "$CC_ROOT" rev-list --count "$BASE"..HEAD 2>/dev/null || echo 0)"

printf 'Repo state: branch `%s`, %s commit(s) ahead of `%s`, %s uncommitted file(s).\n' \
  "$BRANCH" "$AHEAD" "$BASE" "$DIRTY"

if [ -n "$TICKET" ]; then
  DIR="$(cc_ticket_dir "$TICKET")"
  printf 'Active ticket from branch name: %s.\n' "$TICKET"
  if [ -f "$DIR/scope.md" ]; then
    printf 'Scope file exists at .claude/tickets/%s/scope.md — read it before editing; it is the contract for this branch.\n' "$TICKET"
  else
    printf 'No scope file yet. Run /ticket-scope %s before writing code.\n' "$TICKET"
  fi
fi

# Per-area ownership hint: which config governs where the session was launched.
REL="${PWD#"$CC_ROOT"}"
REL="${REL#/}"
if [ -n "$REL" ] && [ -d "$PWD/.claude" ]; then
  printf 'Launched from `%s`, which has its own .claude/ — its skills and CLAUDE.md apply here.\n' "$REL"
fi

# Warn about the one misconfiguration that silently disables the whole gate.
if [ "$(git -C "$CC_ROOT" config --get core.hooksPath 2>/dev/null)" != ".githooks" ]; then
  printf 'Note: git hooks are not installed in this clone (.claude/scripts/install-git-hooks.sh). Human commits are ungated; Claude commits are still gated.\n'
fi

exit 0
