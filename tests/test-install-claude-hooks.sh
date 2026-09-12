#!/usr/bin/env bash
# Tests scripts/install_claude.sh's upsert logic against a throwaway fake
# $HOME — never touches your real ~/.claude.
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

run_install_claude() {
  # install_claude_ding references $DOTFILES directly and expects to be
  # sourced (like install.sh does), not executed as a standalone script.
  HOME="$FAKE_HOME" bash -c '
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/install_claude.sh"
    install_claude_ding
  '
}

echo "test: fresh install adds the marked hook"
run_install_claude > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.claude/settings.json")
assert_eq "exactly one Stop hook entry after fresh install" "1" "$count"

echo "test: re-running after hooks.json itself is unchanged is a no-op (still 1 entry)"
run_install_claude > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.claude/settings.json")
assert_eq "still exactly one Stop hook entry after a repeat run" "1" "$count"

echo "test: an upgrade (the managed command's content changes) REPLACES, not duplicates"
echo "  regression test for: editing an existing hook's command in hooks.json used to"
echo "  leave the old command string installed (dedup was exact-string-match) and just"
echo "  append the new one alongside it, so e.g. ding.wav would play twice on Stop."
jq '.hooks.Stop[0].hooks[0].command = ": dotfiles_managed_hook; echo this-is-the-old-pre-upgrade-command"' \
  "$FAKE_HOME/.claude/settings.json" > "$FAKE_HOME/.claude/settings.json.tmp"
mv "$FAKE_HOME/.claude/settings.json.tmp" "$FAKE_HOME/.claude/settings.json"
run_install_claude > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.claude/settings.json")
assert_eq "exactly one Stop hook entry after an upgrade (old replaced, not duplicated)" "1" "$count"
installed_cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$FAKE_HOME/.claude/settings.json")
expected_cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$DOTFILES/claude/hooks.json")
assert_eq "the installed command is the CURRENT one, not the stale pre-upgrade one" "$expected_cmd" "$installed_cmd"

echo "test: a hand-added hook for the same event (no marker) survives an upgrade"
jq '.hooks.Stop += [{"hooks": [{"type": "command", "command": "echo my-own-hand-added-hook"}]}]' \
  "$FAKE_HOME/.claude/settings.json" > "$FAKE_HOME/.claude/settings.json.tmp"
mv "$FAKE_HOME/.claude/settings.json.tmp" "$FAKE_HOME/.claude/settings.json"
run_install_claude > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.claude/settings.json")
assert_eq "hand-added hook + our one managed hook = 2 entries" "2" "$count"
has_hand_added=$(jq '[.hooks.Stop[].hooks[0].command] | any(. == "echo my-own-hand-added-hook")' "$FAKE_HOME/.claude/settings.json")
assert_eq "the hand-added hook is still present" "true" "$has_hand_added"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
