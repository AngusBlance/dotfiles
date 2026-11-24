#!/usr/bin/env bash
# Tests scripts/install_copilot.sh's upsert logic against a throwaway fake
# $HOME — never touches your real ~/.copilot.
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

run_install_copilot() {
  HOME="$FAKE_HOME" bash -c '
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/install_copilot.sh"
    install_copilot
  '
}

echo "test: fresh install adds the managed Stop hook"
run_install_copilot > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.copilot/hooks.json")
assert_eq "exactly one Stop hook entry after fresh install" "1" "$count"

echo "test: re-running after hooks.json itself is unchanged is a no-op (still 1 entry)"
run_install_copilot > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.copilot/hooks.json")
assert_eq "still exactly one Stop hook entry after a repeat run" "1" "$count"

echo "test: an upgrade (the managed command's content changes) REPLACES, not duplicates"
jq '.hooks.Stop[0].hooks[0].command = ": dotfiles_managed_hook; echo this-is-old-copilot-command"' \
  "$FAKE_HOME/.copilot/hooks.json" > "$FAKE_HOME/.copilot/hooks.json.tmp"
mv "$FAKE_HOME/.copilot/hooks.json.tmp" "$FAKE_HOME/.copilot/hooks.json"
run_install_copilot > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.copilot/hooks.json")
assert_eq "exactly one Stop hook entry after an upgrade (old replaced, not duplicated)" "1" "$count"
installed_cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$FAKE_HOME/.copilot/hooks.json")
expected_cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$DOTFILES/copilot/hooks.json")
assert_eq "the installed command is the CURRENT one, not the stale pre-upgrade one" "$expected_cmd" "$installed_cmd"

echo "test: a hand-added hook for the same event (no marker) survives an upgrade"
jq '.hooks.Stop += [{"hooks": [{"type": "command", "command": "echo my-own-hand-added-hook"}]}]' \
  "$FAKE_HOME/.copilot/hooks.json" > "$FAKE_HOME/.copilot/hooks.json.tmp"
mv "$FAKE_HOME/.copilot/hooks.json.tmp" "$FAKE_HOME/.copilot/hooks.json"
run_install_copilot > /dev/null
count=$(jq '.hooks.Stop | length' "$FAKE_HOME/.copilot/hooks.json")
assert_eq "hand-added hook + our one managed hook = 2 entries" "2" "$count"
has_hand_added=$(jq '[.hooks.Stop[].hooks[0].command] | any(. == "echo my-own-hand-added-hook")' "$FAKE_HOME/.copilot/hooks.json")
assert_eq "the hand-added hook is still present" "true" "$has_hand_added"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
