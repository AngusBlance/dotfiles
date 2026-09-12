#!/usr/bin/env bash
# Tests the nvim/tmux/alacritty/zsh installers (link_config) against a
# throwaway fake $HOME — never touches your real ~/.config.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

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

FAKE_HOME=$(mktemp -d)
cleanup() { rm -rf "$FAKE_HOME"; }
trap cleanup EXIT

run_installers() {
  HOME="$FAKE_HOME" bash -c '
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/lib.sh"
    source "$DOTFILES/scripts/install_nvim.sh"
    source "$DOTFILES/scripts/install_tmux.sh"
    source "$DOTFILES/scripts/install_alacritty.sh"
    source "$DOTFILES/scripts/install_zsh.sh"
    install_nvim
    install_tmux
    install_alacritty
    install_zsh
  '
}

echo "test: fresh machine (no ~/.config at all) - everything gets symlinked"
run_installers > /dev/null
for pair in "nvim:$FAKE_HOME/.config/nvim:$DOTFILES/nvim" \
            "tmux:$FAKE_HOME/.config/tmux:$DOTFILES/tmux" \
            "alacritty:$FAKE_HOME/.config/alacritty:$DOTFILES/alacritty" \
            "zshenv:$FAKE_HOME/.zshenv:$DOTFILES/zsh/.zshenv" \
            "zshrc:$FAKE_HOME/.config/zsh/.zshrc:$DOTFILES/zsh/.zshrc"; do
  name="${pair%%:*}"
  rest="${pair#*:}"
  target="${rest%%:*}"
  source="${rest#*:}"
  if [ -L "$target" ]; then
    assert_eq "$name target is a symlink" "yes" "yes"
  else
    assert_eq "$name target is a symlink" "yes" "no"
  fi
  assert_eq "$name symlink points at the repo source" "$(readlink -f "$source")" "$(readlink -f "$target")"
done

echo "test: pre-existing real config gets backed up, not deleted"
rm -rf "$FAKE_HOME"
FAKE_HOME=$(mktemp -d)
mkdir -p "$FAKE_HOME/.config/nvim"
echo "my hand-written config" > "$FAKE_HOME/.config/nvim/init.lua"
run_installers > /dev/null
assert_eq "original content preserved in the backup" "my hand-written config" "$(cat "$FAKE_HOME/.config/nvim.pre-dotfiles.bak/init.lua" 2>/dev/null)"
assert_eq "nvim target is now a symlink to the repo" "$(readlink -f "$DOTFILES/nvim")" "$(readlink -f "$FAKE_HOME/.config/nvim")"

echo "test: running the installers twice is idempotent (no duplicate backups, no errors)"
out=$(run_installers 2>&1)
exit_code=$?
assert_eq "second run exits cleanly" "0" "$exit_code"
assert_eq "second run doesn't touch the backup again" "my hand-written config" "$(cat "$FAKE_HOME/.config/nvim.pre-dotfiles.bak/init.lua" 2>/dev/null)"
assert_eq "second run reports already-linked, not re-backing-up" "true" "$(echo "$out" | grep -qF 'already linked' && echo true || echo false)"

echo "test: it's one file with two names, not a copy - edits through either path show up in the other"
DUMMY_SRC=$(mktemp -d)/repo-file
mkdir -p "$(dirname "$DUMMY_SRC")"
echo "original" > "$DUMMY_SRC"
DUMMY_TARGET="$FAKE_HOME/dummy-target"
bash -c "source \"$DOTFILES/scripts/lib.sh\"; link_config \"$DUMMY_SRC\" \"$DUMMY_TARGET\""
echo "edited via the .config-side path" > "$DUMMY_TARGET"
assert_eq "editing the target changed the source (same file)" "edited via the .config-side path" "$(cat "$DUMMY_SRC")"
echo "edited via the repo-side path" > "$DUMMY_SRC"
assert_eq "editing the source changed the target (same file, no pull/sync needed)" "edited via the repo-side path" "$(cat "$DUMMY_TARGET")"
rm -rf "$(dirname "$DUMMY_SRC")"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
