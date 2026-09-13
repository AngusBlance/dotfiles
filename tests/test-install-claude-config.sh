#!/usr/bin/env bash
# Tests install_claude_config (skills/CLAUDE.md symlinks + shared settings
# merge) against a throwaway fake $HOME — never touches your real ~/.claude.
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

FAKE_HOME=$(mktemp -d)
# Isolated repo copy so tests can change settings.shared.json freely.
DOTFILES=$(mktemp -d)
rsync -a --exclude='.git' "$REAL_DOTFILES/" "$DOTFILES/"
cleanup() { rm -rf "$FAKE_HOME" "$DOTFILES"; }
trap cleanup EXIT

run_install() {
  HOME="$FAKE_HOME" bash -c '
    set -euo pipefail
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/lib.sh"
    source "$DOTFILES/scripts/install_claude.sh"
    install_claude_config
  '
}

settings="$FAKE_HOME/.claude/settings.json"

echo "test: fresh install links skills and CLAUDE.md, creates settings.json from the shared file"
run_install > /dev/null
assert_eq "fresh install exits cleanly" "0" "$?"
assert_eq "skills is a symlink to the repo" "$(readlink -f "$DOTFILES/claude/skills")" "$(readlink -f "$FAKE_HOME/.claude/skills")"
assert_eq "CLAUDE.md is a symlink to the repo" "$(readlink -f "$DOTFILES/claude/CLAUDE.md")" "$(readlink -f "$FAKE_HOME/.claude/CLAUDE.md")"
assert_eq "the skill is reachable through the link" "true" "$([ -f "$FAKE_HOME/.claude/skills/conventional-commits/SKILL.md" ] && echo true || echo false)"
assert_eq "settings.json has exactly the shared keys" "$(jq -S . "$DOTFILES/claude/settings.shared.json")" "$(jq -S . "$settings")"

echo "test: existing settings keep their other keys; shared keys win"
cat > "$settings" <<'JSON'
{
  "model": "sonnet",
  "hooks": { "Stop": [ { "hooks": [ { "type": "command", "command": "echo keep-me" } ] } ] },
  "autoMode": { "environment": ["machine-specific"] },
  "permissions": { "allow": ["Bash(ls)"] }
}
JSON
run_install > /dev/null
assert_eq "model overridden by shared settings" "opus" "$(jq -r .model "$settings")"
assert_eq "hooks untouched" "echo keep-me" "$(jq -r '.hooks.Stop[0].hooks[0].command' "$settings")"
assert_eq "machine-specific autoMode untouched" '["machine-specific"]' "$(jq -c '.autoMode.environment' "$settings")"
assert_eq "local permissions untouched" '["Bash(ls)"]' "$(jq -c '.permissions.allow' "$settings")"
assert_eq "previous settings backed up" "sonnet" "$(jq -r .model "$settings.shared.bak")"

echo "test: permission lists are combined, keeping order and dropping duplicates"
jq '.permissions = {"allow": ["Bash(ls)", "Bash(git status)"], "deny": ["Read(./.env)"]}' \
  "$DOTFILES/claude/settings.shared.json" > "$DOTFILES/claude/settings.shared.json.tmp"
mv "$DOTFILES/claude/settings.shared.json.tmp" "$DOTFILES/claude/settings.shared.json"
jq '.permissions.allow = ["Bash(npm test)", "Bash(ls)"]' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
run_install > /dev/null
assert_eq "allow = local entries first, then new shared ones, no duplicates" '["Bash(npm test)","Bash(ls)","Bash(git status)"]' "$(jq -c '.permissions.allow' "$settings")"
assert_eq "deny added from shared settings" '["Read(./.env)"]' "$(jq -c '.permissions.deny' "$settings")"

echo "test: a second run changes nothing"
before=$(cat "$settings")
out=$(run_install 2>&1)
assert_eq "second run exits cleanly" "0" "$?"
assert_eq "settings.json unchanged" "$before" "$(cat "$settings")"
assert_eq "reports settings up to date" "true" "$(echo "$out" | grep -qF 'shared settings up to date' && echo true || echo false)"
assert_eq "reports links already in place" "true" "$(echo "$out" | grep -qF 'already linked' && echo true || echo false)"

echo "test: an existing real skills folder is backed up, not deleted"
rm -rf "$FAKE_HOME"
FAKE_HOME=$(mktemp -d)
settings="$FAKE_HOME/.claude/settings.json"
mkdir -p "$FAKE_HOME/.claude/skills/my-skill"
echo "hand-written skill" > "$FAKE_HOME/.claude/skills/my-skill/SKILL.md"
run_install > /dev/null
assert_eq "original skill preserved in the backup" "hand-written skill" "$(cat "$FAKE_HOME/.claude/skills.pre-dotfiles.bak/my-skill/SKILL.md" 2>/dev/null)"
assert_eq "skills now links to the repo" "$(readlink -f "$DOTFILES/claude/skills")" "$(readlink -f "$FAKE_HOME/.claude/skills")"

echo "test: an empty settings.json is treated like a missing one"
: > "$settings"
run_install > /dev/null 2>&1
assert_eq "shared model applied to an empty settings.json" "opus" "$(jq -r .model "$settings" 2>/dev/null)"

echo "test: invalid JSON is left untouched and the install fails loudly"
printf '{not json' > "$settings"
out=$(run_install 2>&1)
code=$?
assert_eq "exits non-zero" "1" "$code"
assert_eq "file unchanged" "{not json" "$(cat "$settings")"
assert_eq "explains what went wrong" "true" "$(echo "$out" | grep -qF 'not a JSON object' && echo true || echo false)"

echo "test: a merge error (non-list permission value) never clobbers settings.json"
printf '{"permissions": {"allow": "Bash(ls)"}}\n' > "$settings"
before=$(cat "$settings")
HOME="$FAKE_HOME" bash -c '
  DOTFILES="'"$DOTFILES"'"
  source "$DOTFILES/scripts/lib.sh"
  source "$DOTFILES/scripts/install_claude.sh"
  install_claude_config
' > /dev/null 2>&1
code=$?
assert_eq "exits non-zero even without set -e" "1" "$code"
assert_eq "file unchanged" "$before" "$(cat "$settings")"

echo "test: hooks and shared settings installed in the same run don't undo each other"
rm -f "$settings" "$settings".*bak
run_both() {
  HOME="$FAKE_HOME" bash -c '
    set -euo pipefail
    DOTFILES="'"$DOTFILES"'"
    source "$DOTFILES/scripts/lib.sh"
    source "$DOTFILES/scripts/install_claude.sh"
    install_claude_ding
    install_claude_config
  '
}
run_both > /dev/null
assert_eq "every managed hook event present" "$(jq -c '.hooks | keys' "$DOTFILES/claude/hooks.json")" "$(jq -c '.hooks | keys' "$settings")"
assert_eq "shared model applied" "opus" "$(jq -r .model "$settings")"
before=$(cat "$settings")
out=$(run_both 2>&1)
assert_eq "second combined run leaves settings.json unchanged" "$before" "$(cat "$settings")"
assert_eq "second combined run reports no hook changes" "false" "$(echo "$out" | grep -qE 'hook (installed|updated)' && echo true || echo false)"

echo "test: machine-local files are never created"
for f in .credentials.json settings.local.json projects history.jsonl; do
  assert_eq "$f not created" "false" "$([ -e "$FAKE_HOME/.claude/$f" ] && echo true || echo false)"
done

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
