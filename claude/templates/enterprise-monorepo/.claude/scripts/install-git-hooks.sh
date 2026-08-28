#!/usr/bin/env bash
# install-git-hooks.sh — point git at .githooks/ so humans run the same gate
# Claude does. This is the husky role, without the dependency.
#
# Run once per clone:  .claude/scripts/install-git-hooks.sh
# Undo:                git config --unset core.hooksPath

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

cc_in_git || { cc_err "not a git repository"; exit 1; }

HOOKS_DIR="$CC_ROOT/.githooks"
mkdir -p "$HOOKS_DIR"

# --- pre-commit -------------------------------------------------------------

cat > "$HOOKS_DIR/pre-commit" <<'HOOK'
#!/usr/bin/env bash
# Managed by .claude/scripts/install-git-hooks.sh — edit preflight.sh, not this.
root="$(git rev-parse --show-toplevel)"
exec "$root/.claude/scripts/preflight.sh" --changed
HOOK

# --- commit-msg -------------------------------------------------------------

cat > "$HOOKS_DIR/commit-msg" <<'HOOK'
#!/usr/bin/env bash
# Conventional Commits check. See .claude/conventions/git.md.
msg_file="$1"
first_line="$(head -n1 "$msg_file")"

# Allow merges, reverts, and fixup/squash commits through untouched.
case "$first_line" in
  Merge*|Revert*|fixup!*|squash!*) exit 0 ;;
esac

pattern='^(feat|fix|chore|refactor|docs|test|perf|ci|build|style)(\([a-z0-9._/-]+\))?!?: .{1,72}$'
if ! printf '%s' "$first_line" | grep -qE "$pattern"; then
  cat >&2 <<MSG
commit-msg: subject does not follow Conventional Commits.

  got:      $first_line
  expected: <type>(<scope>): <imperative summary>   (<= 72 chars)
  types:    feat fix chore refactor docs test perf ci build style

See .claude/conventions/git.md
MSG
  exit 1
fi
exit 0
HOOK

chmod +x "$HOOKS_DIR/pre-commit" "$HOOKS_DIR/commit-msg"
git -C "$CC_ROOT" config core.hooksPath .githooks

cat <<EOF
Installed git hooks in .githooks/ and set core.hooksPath.

  pre-commit  → .claude/scripts/preflight.sh --changed
  commit-msg  → Conventional Commits check

Claude runs the same preflight through a PreToolUse hook on \`git commit\`, so
both paths enforce one gate. Commit \`.githooks/\` to the repo; each clone runs
this script once.

Bypass (do not make it a habit): git commit --no-verify
EOF
