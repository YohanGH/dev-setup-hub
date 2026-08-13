#!/usr/bin/env bash
# context-budget.sh — what does this configuration actually cost?
#
# Every discussion about "keeping context small" is guesswork until someone
# measures it. This classifies every instruction file by WHEN it enters the
# context window, so you can see what you pay on every turn versus what you pay
# only when it is relevant.
#
#   .claude/scripts/context-budget.sh              # whole repo
#   .claude/scripts/context-budget.sh apps/api     # what a session started there pays
#   .claude/scripts/context-budget.sh --files      # per-file detail, largest first
#
# Token figures are an estimate (~4 chars/token for English prose). Use them to
# compare options, not as an invoice.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

START=""
DETAIL=0
for arg in "$@"; do
  case "$arg" in
    --files) DETAIL=1 ;;
    -h|--help) sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) START="$arg" ;;
  esac
done

cd "$CC_ROOT" || exit 1

bytes_of() { [ -f "$1" ] && wc -c < "$1" | tr -d ' ' || echo 0; }
tokens()   { echo $(( ${1:-0} / 4 )); }

# Extracts a skill's frontmatter identity — the part that is always in the
# skill list, whether or not the skill is ever used.
skill_index_bytes() {
  awk '
    NR==1 && $0=="---" { inFm=1; next }
    inFm && $0=="---"  { exit }
    inFm && /^(name|description|when_to_use):/ { keep=1; print; next }
    inFm && keep && /^[[:space:]]/ { print; next }
    inFm { keep=0 }
  ' "$1" 2>/dev/null | wc -c | tr -d ' '
}

has_paths_frontmatter() {
  awk 'NR==1 && $0=="---"{inFm=1;next} inFm && $0=="---"{exit} inFm && /^paths:/{found=1} END{exit !found}' "$1" 2>/dev/null
}

# --- collect ----------------------------------------------------------------

ALWAYS=0; ALWAYS_N=0
ONDEMAND=0; ONDEMAND_N=0
INDEX=0; BODIES=0; SKILL_N=0
NEVER=0; NEVER_N=0
DETAIL_ROWS=""

add_row() { DETAIL_ROWS="${DETAIL_ROWS}$1|$2|$3"$'\n'; }

# Root CLAUDE.md — always loaded, in full, every session.
for f in CLAUDE.md .claude/CLAUDE.md; do
  [ -f "$f" ] || continue
  b="$(bytes_of "$f")"; ALWAYS=$((ALWAYS + b)); ALWAYS_N=$((ALWAYS_N + 1))
  add_row "$b" "always" "$f"
done

# Nested CLAUDE.md — on demand when Claude reads a file in that directory,
# or at launch if the session starts there.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  case "$f" in ./CLAUDE.md|./.claude/CLAUDE.md) continue ;; esac
  b="$(bytes_of "${f#./}")"; ONDEMAND=$((ONDEMAND + b)); ONDEMAND_N=$((ONDEMAND_N + 1))
  add_row "$b" "on-demand" "${f#./}"
done <<EOF
$(find . -name CLAUDE.md -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null)
EOF

# Rules: with paths: → on demand. Without → always.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  f="${f#./}"; b="$(bytes_of "$f")"
  if has_paths_frontmatter "$f"; then
    ONDEMAND=$((ONDEMAND + b)); ONDEMAND_N=$((ONDEMAND_N + 1)); add_row "$b" "on-demand" "$f"
  else
    ALWAYS=$((ALWAYS + b)); ALWAYS_N=$((ALWAYS_N + 1)); add_row "$b" "always" "$f"
  fi
done <<EOF
$(find . -path '*/.claude/rules/*.md' -not -path './.git/*' 2>/dev/null)
EOF

# Skills: identity is always in the list; the body loads only when used.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  f="${f#./}"
  b="$(bytes_of "$f")"; ix="$(skill_index_bytes "$f")"
  INDEX=$((INDEX + ix)); BODIES=$((BODIES + b)); SKILL_N=$((SKILL_N + 1))
  add_row "$b" "on-use" "$f"
done <<EOF
$(find . -name SKILL.md -not -path './.git/*' -not -path './node_modules/*' 2>/dev/null)
EOF

# Commands: body loads only when you type the name.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  f="${f#./}"; b="$(bytes_of "$f")"
  case "$f" in */README.md) continue ;; esac
  BODIES=$((BODIES + b))
  add_row "$b" "on-use" "$f"
done <<EOF
$(find . -path '*/.claude/commands/*.md' -not -path './.git/*' 2>/dev/null)
EOF

# Conventions and skill reference files: never auto-loaded.
while IFS= read -r f; do
  [ -z "$f" ] && continue
  f="${f#./}"; b="$(bytes_of "$f")"
  NEVER=$((NEVER + b)); NEVER_N=$((NEVER_N + 1))
  add_row "$b" "never" "$f"
done <<EOF
$(find . \( -path '*/.claude/conventions/*.md' -o -path '*/.claude/skills/*/references/*.md' \) -not -path './.git/*' 2>/dev/null)
EOF

# --- report -----------------------------------------------------------------

printf '\n'
printf 'Context budget — %s\n' "$CC_ROOT"
printf '%s\n' "------------------------------------------------------------------"
printf '%-34s %10s %9s %7s\n' "WHEN IT LOADS" "BYTES" "~TOKENS" "FILES"
printf '%s\n' "------------------------------------------------------------------"
printf '%-34s %10s %9s %7s\n' "every turn (CLAUDE.md, bare rules)" "$ALWAYS"   "$(tokens $ALWAYS)"   "$ALWAYS_N"
printf '%-34s %10s %9s %7s\n' "skill list (names+descriptions)"    "$INDEX"    "$(tokens $INDEX)"    "$SKILL_N"
printf '%s\n' "------------------------------------------------------------------"
FIXED=$((ALWAYS + INDEX))
printf '%-34s %10s %9s\n' "FIXED COST PER SESSION" "$FIXED" "$(tokens $FIXED)"
printf '%s\n' "------------------------------------------------------------------"
printf '%-34s %10s %9s %7s\n' "on demand (nested/path-scoped)" "$ONDEMAND" "$(tokens $ONDEMAND)" "$ONDEMAND_N"
printf '%-34s %10s %9s %7s\n' "on use (skill+command bodies)"  "$BODIES"   "$(tokens $BODIES)"   "$SKILL_N"
printf '%-34s %10s %9s %7s\n' "never (conventions, references)" "$NEVER"   "$(tokens $NEVER)"    "$NEVER_N"
printf '%s\n' "------------------------------------------------------------------"
TOTAL=$((ALWAYS + INDEX + ONDEMAND + BODIES + NEVER))
printf '%-34s %10s %9s\n' "TOTAL CONFIG ON DISK" "$TOTAL" "$(tokens $TOTAL)"
printf '\n'

if [ "$TOTAL" -gt 0 ]; then
  PCT=$(( FIXED * 100 / TOTAL ))
  printf 'You pay %s%% of this configuration on every turn.\n' "$PCT"
  if [ "$PCT" -gt 35 ]; then
    printf 'That is high. Move detail out of CLAUDE.md into path-scoped rules or skills.\n'
  else
    printf 'The rest loads only when it is relevant to the task.\n'
  fi
fi

# Per-start-directory view.
if [ -n "$START" ] && [ -d "$START" ]; then
  printf '\n'
  printf 'Session started in %s\n' "$START"
  printf '%s\n' "------------------------------------------------------------------"
  L=0
  d="$START"
  while :; do
    [ -f "$d/CLAUDE.md" ] && { b="$(bytes_of "$d/CLAUDE.md")"; L=$((L+b)); printf '  %-52s %8s B\n' "$d/CLAUDE.md" "$b"; }
    [ "$d" = "." ] && break
    d="$(dirname "$d")"
  done
  A=0
  for f in "$START"/.claude/agents/*.md; do [ -f "$f" ] && A=$((A+1)); done
  S=0
  while IFS= read -r f; do [ -n "$f" ] && S=$((S+1)); done <<EOF
$(find "$START" -name SKILL.md 2>/dev/null)
EOF
  printf '%s\n' "------------------------------------------------------------------"
  printf '  CLAUDE.md chain loaded at launch: %s B (~%s tokens)\n' "$L" "$(tokens $L)"
  printf '  subagents in scope (this dir + ancestors): %s\n' "$A"
  printf '  skills reachable under this dir: %s\n' "$S"
  [ -f "$START/.claude/settings.json" ] \
    && printf '  settings.json: apply here (hooks, plugins, permissions)\n' \
    || printf '  settings.json: none — the root file applies only if you start at the root\n'
fi

if [ "$DETAIL" -eq 1 ]; then
  printf '\nPer file, largest first:\n'
  printf '%s\n' "------------------------------------------------------------------"
  printf '%s' "$DETAIL_ROWS" | sort -t'|' -k1 -rn | head -n 30 | \
    while IFS='|' read -r b when path; do
      [ -z "$b" ] && continue
      printf '  %8s B  %-10s %s\n' "$b" "$when" "$path"
    done
fi

printf '\n'
