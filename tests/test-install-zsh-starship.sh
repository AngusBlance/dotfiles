#!/usr/bin/env bash
# Tests install_zsh's starship bootstrap, mocking curl so nothing real gets
# downloaded or installed.
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

make_fake_bin() {
  local dir
  dir=$(mktemp -d)
  local b
  for b in ls cat mktemp readlink dirname basename cp mv rm mkdir chmod bash env grep sed sort head ln; do
    ln -sf "$(command -v "$b")" "$dir/$b"
  done
  echo "$dir"
}

run_install_zsh() {
  local path="$1" home="$2"
  PATH="$path" HOME="$home" bash -c '
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/lib.sh"
    source "$DOTFILES/scripts/install_zsh.sh"
    install_zsh
  '
}

echo "test: starship missing - attempts install via its curl script"
FAKE_BIN=$(make_fake_bin)
CURL_LOG=$(mktemp -u)
cat > "$FAKE_BIN/curl" <<EOF
#!/bin/bash
echo "\$*" >> "$CURL_LOG"
echo "#!/bin/sh"
echo "exit 0"
EOF
chmod +x "$FAKE_BIN/curl"
cat > "$FAKE_BIN/sh" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$FAKE_BIN/sh"
TEST_HOME=$(mktemp -d)
out=$(run_install_zsh "$FAKE_BIN" "$TEST_HOME")
assert_eq "reports installed" "true" "$(echo "$out" | grep -qF "starship installed" && echo true || echo false)"
assert_eq "fetched starship's real install script URL" "true" "$(grep -qF "starship.rs/install.sh" "$CURL_LOG" && echo true || echo false)"
rm -rf "$FAKE_BIN" "$TEST_HOME" "$CURL_LOG"

echo "test: starship already present - skips install, no curl call"
FAKE_BIN=$(make_fake_bin)
cat > "$FAKE_BIN/starship" <<'EOF'
#!/bin/bash
exit 0
EOF
chmod +x "$FAKE_BIN/starship"
TEST_HOME=$(mktemp -d)
out=$(run_install_zsh "$FAKE_BIN" "$TEST_HOME")
assert_eq "reports already installed" "true" "$(echo "$out" | grep -qF "starship already installed" && echo true || echo false)"
rm -rf "$FAKE_BIN" "$TEST_HOME"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
