#!/usr/bin/env bash
# Tests install_tmux's plugin bootstrap (TPM + Catppuccin) against a mocked
# git and a stub tpm/bin/install_plugins - no real network calls, no real
# TPM behavior depended on.
#
# Uses an isolated copy of the repo (without tmux/plugins/) rather than the
# real dev checkout: tmux/plugins/ is gitignored but often physically
# present locally from real use, which would make "fresh install" tests
# silently see it as already installed.
set -uo pipefail

REAL_DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

pass=0
fail=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ok   - $desc"
    pass=$((pass + 1))
  else
    echo "  FAIL - $desc (expected [$expected], got [$actual])"
    fail=$((fail + 1))
  fi
}

DOTFILES=$(mktemp -d)
rsync -a --exclude='.git' --exclude='tmux/plugins' "$REAL_DOTFILES/" "$DOTFILES/"

FAKE_HOME=$(mktemp -d)
FAKE_BIN=$(mktemp -d)
GIT_LOG=$(mktemp -u)
cleanup() { rm -rf "$FAKE_HOME" "$FAKE_BIN" "$DOTFILES" "$GIT_LOG"; }
trap cleanup EXIT

for b in ls cat mktemp readlink dirname basename cp mv rm mkdir chmod bash env grep sed sort head ln; do
  ln -sf "$(command -v "$b")" "$FAKE_BIN/$b"
done

# Mocked git: logs the call, then creates the target dir with a stub
# tpm/bin/install_plugins so the real TPM script never has to run.
cat > "$FAKE_BIN/git" <<EOF
#!/bin/bash
echo "\$*" >> "$GIT_LOG"
if [ "\$1" = "clone" ]; then
  target="\${@: -1}"
  mkdir -p "\$target/bin"
  cat > "\$target/bin/install_plugins" <<'INNER'
#!/bin/bash
exit 0
INNER
  chmod +x "\$target/bin/install_plugins"
fi
EOF
chmod +x "$FAKE_BIN/git"

run_install_tmux() {
  PATH="$FAKE_BIN:$PATH" HOME="$FAKE_HOME" bash -c '
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/lib.sh"
    source "$DOTFILES/scripts/install_tmux.sh"
    install_tmux
  '
}

echo "test: fresh install clones both tpm and catppuccin, reports installed"
out=$(run_install_tmux)
assert_eq "reports installed" "true" "$(echo "$out" | grep -qF "tmux plugins installed" && echo true || echo false)"
assert_eq "cloned tpm" "true" "$(grep -qF "tpm" "$GIT_LOG" && echo true || echo false)"
assert_eq "cloned catppuccin" "true" "$(grep -qF "catppuccin" "$GIT_LOG" && echo true || echo false)"
clone_count_before="$(wc -l < "$GIT_LOG")"

echo "test: re-running does NOT re-clone, reports already installed"
out=$(run_install_tmux)
assert_eq "reports already installed" "true" "$(echo "$out" | grep -qF "tmux plugins already installed" && echo true || echo false)"
clone_count_after="$(wc -l < "$GIT_LOG")"
assert_eq "no new git clone calls on the second run" "$clone_count_before" "$clone_count_after"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
