#!/usr/bin/env bash
# scan-secrets.sh — cheap, deterministic secret check over changed files.
#
# This is a last line of defence, not a security product. It catches the
# accidents (a pasted key, a committed .env); it does not catch a determined
# leak. Pair it with a real scanner in CI.
#
# Prints one line per hit and exits 1; prints nothing and exits 0 when clean.

SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)"
# shellcheck source=lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

FILES="$(cc_changed_files)"
[ -z "$FILES" ] && exit 0

# Files that must never be committed at all.
FORBIDDEN_PATHS='(^|/)\.env($|\.)|\.pem$|\.p12$|\.pfx$|(^|/)id_rsa$|(^|/)id_ed25519$|(^|/)secrets?/'

# High-signal patterns only. Every extra pattern that fires on test fixtures
# trains people to use --no-verify, which is worse than no check.
PATTERNS='
AKIA[0-9A-Z]{16}
ASIA[0-9A-Z]{16}
gh[pousr]_[A-Za-z0-9]{36,}
github_pat_[A-Za-z0-9_]{22,}
sk-(live|proj)-[A-Za-z0-9]{20,}
xox[abprs]-[A-Za-z0-9-]{10,}
-----BEGIN [A-Z ]*PRIVATE KEY-----
AIza[0-9A-Za-z_-]{35}
eyJhbGciOi[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}
(password|passwd|secret|api[_-]?key|access[_-]?token)[[:space:]]*[:=][[:space:]]*["'"'"'][^"'"'"'[:space:]]{12,}["'"'"']
'

FOUND=0

while IFS= read -r f; do
  [ -z "$f" ] && continue

  if printf '%s' "$f" | grep -qE "$FORBIDDEN_PATHS"; then
    printf 'secret: %s — this file must never be committed\n' "$f"
    FOUND=1
    continue
  fi

  # Skip binaries and lockfiles (huge, and full of base64-looking hashes).
  case "$f" in
    *.lock|*lock.json|*.lockb|*.min.js|*.map|*.png|*.jpg|*.jpeg|*.gif|*.pdf|*.zip|*.gz|*.woff*) continue ;;
  esac
  [ -f "$CC_ROOT/$f" ] || continue
  grep -Iq . "$CC_ROOT/$f" 2>/dev/null || continue   # binary

  while IFS= read -r pattern; do
    [ -z "$pattern" ] && continue
    hit="$(grep -nEI -m1 "$pattern" "$CC_ROOT/$f" 2>/dev/null)" || continue
    [ -z "$hit" ] && continue
    line="${hit%%:*}"
    # Allow an explicit, reviewed waiver on the same line.
    if printf '%s' "$hit" | grep -q 'allow-secret'; then continue; fi
    printf 'secret: %s:%s — matches %s\n' "$f" "$line" "$pattern"
    FOUND=1
  done <<EOF
$PATTERNS
EOF
done <<EOF
$FILES
EOF

exit "$FOUND"
