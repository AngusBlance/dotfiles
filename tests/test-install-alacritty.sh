#!/usr/bin/env bash
# Tests install_alacritty's Nerd Font check, and specifically guards against
# a real bug hit while building it: `grep -q` exits the instant it finds a
# match, closing the pipe early and killing a still-writing producer with
# SIGPIPE. Under `set -o pipefail` (which install.sh uses), that poisons the
# whole pipeline's exit status to non-zero even though grep DID match, so
# `if producer | grep -q pattern; then` always takes the else branch.
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

echo "test: regression - a grep -q check on a slow multi-line producer under pipefail"
echo "  a synthetic producer stands in for fc-list: many lines, deliberately slow,"
echo "  so grep has time to match and exit before the producer finishes writing -"
echo "  this reliably reproduces the SIGPIPE race regardless of real font data."
slow_producer() {
  echo "line 1: JetBrainsMono Nerd Font Mono"
  for i in $(seq 1 50); do
    sleep 0.02
    echo "line $i: some other font family"
  done
}

(
  set -o pipefail
  if slow_producer | grep -qi "JetBrainsMono Nerd Font" > /dev/null; then
    echo BUGGY_RESULT=match
  else
    echo BUGGY_RESULT=nomatch
  fi
) > /tmp/buggy_result.$$ 2>&1
buggy_result=$(grep -o "BUGGY_RESULT=.*" /tmp/buggy_result.$$)
rm -f /tmp/buggy_result.$$
assert_eq "the OLD buggy pattern (grep -q) fails to see the match under pipefail" "BUGGY_RESULT=nomatch" "$buggy_result"

(
  set -o pipefail
  if slow_producer | grep -i "JetBrainsMono Nerd Font" > /dev/null; then
    echo FIXED_RESULT=match
  else
    echo FIXED_RESULT=nomatch
  fi
) > /tmp/fixed_result.$$ 2>&1
fixed_result=$(grep -o "FIXED_RESULT=.*" /tmp/fixed_result.$$)
rm -f /tmp/fixed_result.$$
assert_eq "the FIXED pattern (plain grep) correctly sees the match under pipefail" "FIXED_RESULT=match" "$fixed_result"

echo "test: install_alacritty.sh doesn't use the buggy 'grep -q' form on the fc-list check"
if grep -n "fc-list" "$DOTFILES/scripts/install_alacritty.sh" | grep -q -- "-q"; then
  assert_eq "fc-list check avoids grep -q" "no -q used" "-q found"
else
  assert_eq "fc-list check avoids grep -q" "no -q used" "no -q used"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
