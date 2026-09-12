#!/usr/bin/env bash
# Tests install.sh's git/jq dependency checks, using a restricted PATH so
# real system tools stay hidden without needing to touch anything.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$DOTFILES/install.sh"

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

make_fake_bin() {
  local dir
  dir=$(mktemp -d)
  local bins=(git ls cat mktemp readlink dirname basename cp mv rm mkdir chmod bash env grep sed sort head "$@")
  local b
  for b in "${bins[@]}"; do
    [ -e "$dir/$b" ] && continue
    command -v "$b" > /dev/null 2>&1 && ln -sf "$(command -v "$b")" "$dir/$b"
  done
  echo "$dir"
}

echo "test: git missing exits cleanly with a clear message"
FAKE_BIN=$(make_fake_bin)
rm -f "$FAKE_BIN/git"
TEST_HOME=$(mktemp -d)
out=$(PATH="$FAKE_BIN" HOME="$TEST_HOME" bash "$INSTALL" 2>&1)
code=$?
assert_eq "exits non-zero" "1" "$code"
assert_eq "mentions git" "true" "$(echo "$out" | grep -qi "git" && echo true || echo false)"
rm -rf "$FAKE_BIN" "$TEST_HOME"

echo "test: jq missing with no package manager detected exits cleanly"
FAKE_BIN=$(make_fake_bin)
TEST_HOME=$(mktemp -d)
out=$(PATH="$FAKE_BIN" HOME="$TEST_HOME" bash "$INSTALL" 2>&1)
code=$?
assert_eq "exits non-zero" "1" "$code"
assert_eq "says it couldn't detect a package manager" "true" "$(echo "$out" | grep -qi "package manager" && echo true || echo false)"
rm -rf "$FAKE_BIN" "$TEST_HOME"

echo "test: jq missing with apt detected calls 'sudo apt install -y jq'"
FAKE_BIN=$(make_fake_bin)
cat > "$FAKE_BIN/apt" <<'SCRIPT'
#!/bin/bash
echo "APT_CALLED:$*"
SCRIPT
cat > "$FAKE_BIN/sudo" <<'SCRIPT'
#!/bin/bash
echo "SUDO_CALLED:$*"
"$@"
SCRIPT
chmod +x "$FAKE_BIN/apt" "$FAKE_BIN/sudo"
TEST_HOME=$(mktemp -d)
out=$(PATH="$FAKE_BIN" HOME="$TEST_HOME" bash "$INSTALL" 2>&1)
assert_eq "invoked sudo apt install -y jq" "true" "$(echo "$out" | grep -qF "SUDO_CALLED:apt install -y jq" && echo true || echo false)"
rm -rf "$FAKE_BIN" "$TEST_HOME"

echo "test: git and jq both present - dependency check doesn't block install"
TEST_HOME=$(mktemp -d)
out=$(HOME="$TEST_HOME" bash "$INSTALL" 2>&1)
assert_eq "reaches the nvim install step" "true" "$(echo "$out" | grep -qF "== nvim ==" && echo true || echo false)"
rm -rf "$TEST_HOME"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
