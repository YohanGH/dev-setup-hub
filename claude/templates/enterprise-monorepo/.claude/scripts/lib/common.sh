#!/usr/bin/env bash
# Shared helpers for .claude/scripts and .claude/hooks.
# Source it, don't execute it:  . "$(dirname "$0")/lib/common.sh"
#
# Contract: nothing here writes to stdout unless asked. Hook stdout is context
# (SessionStart / UserPromptSubmit) or parsed as JSON — stray echoes break it.
# Diagnostics go to stderr via cc_log.

set -uo pipefail

# --- paths ------------------------------------------------------------------

cc_repo_root() {
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "$CLAUDE_PROJECT_DIR" ]; then
    printf '%s\n' "$CLAUDE_PROJECT_DIR"
    return 0
  fi
  git rev-parse --show-toplevel 2>/dev/null || pwd
}

CC_ROOT="$(cc_repo_root)"
export CC_ROOT

# --- logging (stderr only) --------------------------------------------------

cc_log()  { printf '%s\n' "$*" >&2; }
cc_warn() { printf 'warning: %s\n' "$*" >&2; }
cc_err()  { printf 'error: %s\n' "$*" >&2; }

cc_have() { command -v "$1" >/dev/null 2>&1; }

# --- hook input -------------------------------------------------------------

# Reads the hook JSON from stdin once. Safe to call when stdin is empty.
cc_hook_input() {
  if [ -t 0 ]; then printf '%s' ''; else cat; fi
}

# cc_json <json> <jq-path> [default]
# Returns the default when jq is missing, the JSON is unparseable, or the
# value is null/absent. Never fails the caller.
#
# Deliberately does NOT use jq's `//` operator: `false // "x"` yields "x",
# because `//` treats false as empty. A boolean field like stop_hook_active
# would then read as its default and invert the hook's logic.
cc_json() {
  local json="$1" path="$2" default="${3:-}" out
  if [ -z "$json" ] || ! cc_have jq; then
    printf '%s' "$default"; return 0
  fi
  out="$(printf '%s' "$json" | jq -r "$path" 2>/dev/null)" || out=""
  if [ -z "$out" ] || [ "$out" = "null" ]; then
    printf '%s' "$default"
  else
    printf '%s' "$out"
  fi
}

# --- hook output ------------------------------------------------------------

# cc_emit_deny <event> <reason>   — block a tool call (PreToolUse)
cc_emit_deny() {
  local event="$1" reason="$2"
  if cc_have jq; then
    jq -n --arg e "$event" --arg r "$reason" \
      '{hookSpecificOutput:{hookEventName:$e,permissionDecision:"deny",permissionDecisionReason:$r}}'
  else
    cc_err "$reason"
    exit 2
  fi
}

# cc_emit_ask <event> <reason>    — escalate to the user instead of blocking
cc_emit_ask() {
  local event="$1" reason="$2"
  if cc_have jq; then
    jq -n --arg e "$event" --arg r "$reason" \
      '{hookSpecificOutput:{hookEventName:$e,permissionDecision:"ask",permissionDecisionReason:$r}}'
  else
    exit 0
  fi
}

# cc_emit_context <event> <text>  — inject context (UserPromptSubmit)
cc_emit_context() {
  local event="$1" text="$2"
  cc_have jq || { printf '%s\n' "$text"; return 0; }
  jq -n --arg e "$event" --arg c "$text" \
    '{hookSpecificOutput:{hookEventName:$e,additionalContext:$c}}'
}

# cc_emit_message <text>          — a note shown to the user, not to Claude
cc_emit_message() {
  cc_have jq || return 0
  jq -n --arg m "$1" '{systemMessage:$m,suppressOutput:true}'
}

# --- git --------------------------------------------------------------------

cc_in_git() { git -C "$CC_ROOT" rev-parse --git-dir >/dev/null 2>&1; }

cc_default_branch() {
  local b
  b="$(git -C "$CC_ROOT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)"
  if [ -n "$b" ]; then printf '%s\n' "${b#origin/}"; return 0; fi
  for b in main master develop; do
    if git -C "$CC_ROOT" show-ref --verify --quiet "refs/heads/$b"; then
      printf '%s\n' "$b"; return 0
    fi
  done
  printf '%s\n' "main"
}

cc_merge_base() {
  local base; base="$(cc_default_branch)"
  git -C "$CC_ROOT" merge-base HEAD "$base" 2>/dev/null || \
    git -C "$CC_ROOT" rev-parse HEAD 2>/dev/null || true
}

cc_current_branch() {
  git -C "$CC_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || printf '%s\n' "(detached)"
}

# Files changed vs the merge base, plus uncommitted ones. Existing files only.
cc_changed_files() {
  cc_in_git || return 0
  local base; base="$(cc_merge_base)"
  {
    [ -n "$base" ] && git -C "$CC_ROOT" diff --name-only --diff-filter=d "$base"...HEAD 2>/dev/null
    git -C "$CC_ROOT" diff --name-only --diff-filter=d 2>/dev/null
    git -C "$CC_ROOT" diff --name-only --diff-filter=d --cached 2>/dev/null
    git -C "$CC_ROOT" ls-files --others --exclude-standard 2>/dev/null
  } | sort -u | while IFS= read -r f; do
    [ -n "$f" ] && [ -f "$CC_ROOT/$f" ] && printf '%s\n' "$f"
  done
}

# A short fingerprint of the *content* of the current change — used to avoid
# repeating work on an unchanged tree.
#
# Hashes the diff itself, not `git status`, for two reasons: status output is
# identical before and after an edit to an already-modified file (so a real fix
# would look like no change), and it flips on unrelated untracked noise such as
# a cache directory (so a gate could re-fire without anything having changed).
cc_worktree_fingerprint() {
  cc_in_git || { printf '%s' "nogit"; return 0; }
  {
    git -C "$CC_ROOT" rev-parse HEAD 2>/dev/null
    git -C "$CC_ROOT" diff HEAD 2>/dev/null
    git -C "$CC_ROOT" ls-files --others --exclude-standard 2>/dev/null
  } | { if cc_have sha1sum; then sha1sum; else shasum; fi; } 2>/dev/null | cut -c1-12
}

# --- ticket -----------------------------------------------------------------

CC_TICKET_PATTERN="${CC_TICKET_PATTERN:-[A-Z][A-Z0-9]+-[0-9]+}"

# Extracts the first ticket id from its argument (branch name, prompt, ...).
cc_extract_ticket() {
  printf '%s' "${1:-}" | grep -oE "$CC_TICKET_PATTERN" | head -n1 || true
}

cc_branch_ticket() { cc_extract_ticket "$(cc_current_branch)"; }

cc_ticket_dir() { printf '%s/.claude/tickets/%s' "$CC_ROOT" "$1"; }

# --- package manager / stack ------------------------------------------------

cc_detect_pm() {
  local d="${1:-$CC_ROOT}"
  [ -f "$d/bun.lockb" ]          && { printf 'bun\n';  return 0; }
  [ -f "$d/pnpm-lock.yaml" ]     && { printf 'pnpm\n'; return 0; }
  [ -f "$d/yarn.lock" ]          && { printf 'yarn\n'; return 0; }
  [ -f "$d/package-lock.json" ]  && { printf 'npm\n';  return 0; }
  [ -f "$d/package.json" ]       && { printf 'npm\n';  return 0; }
  printf 'none\n'
}

# True when package.json declares the given script.
cc_has_script() {
  local script="$1" pkg="${2:-$CC_ROOT/package.json}"
  [ -f "$pkg" ] || return 1
  if cc_have jq; then
    jq -e --arg s "$script" '.scripts[$s] // empty' "$pkg" >/dev/null 2>&1
  else
    grep -qE "\"$script\"[[:space:]]*:" "$pkg"
  fi
}

# Prints the command that runs a package.json script with the right manager.
cc_run_script() {
  local script="$1" pm; pm="$(cc_detect_pm)"
  case "$pm" in
    bun)  printf 'bun run %s\n' "$script" ;;
    pnpm) printf 'pnpm run %s\n' "$script" ;;
    yarn) printf 'yarn %s\n' "$script" ;;
    npm)  printf 'npm run --silent %s\n' "$script" ;;
    *)    return 1 ;;
  esac
}
