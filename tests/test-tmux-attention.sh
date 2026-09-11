#!/usr/bin/env bash
# Tests claude/scripts/tmux-flag.sh and tmux-unflag.sh against a throwaway,
# detached tmux session — never touches your real tmux session.
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLAG="$DOTFILES/claude/scripts/tmux-flag.sh"
UNFLAG="$DOTFILES/claude/scripts/tmux-unflag.sh"
SESSION="dotfiles_test_attn_$$"

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

cleanup() {
  tmux kill-session -t "$SESSION" 2>/dev/null || true
}
trap cleanup EXIT

tmux new-session -d -s "$SESSION" -x 80 -y 24
tmux new-window -d -t "$SESSION"
# base-index is a global tmux option (the real tmux.conf sets it to 1), so
# don't assume window 0 exists - read back whatever indices actually got used.
windows=($(tmux list-windows -t "$SESSION" -F '#{window_index}' | sort -n))
win1="${windows[0]}"
win2="${windows[1]}"
pane=$(tmux list-panes -t "$SESSION:$win2" -F '#{pane_id}')

echo "test: outside tmux (no TMUX_PANE) - tmux commands no-op, bell still fires"
out=$(env -u TMUX_PANE -u TMUX "$FLAG" 2>&1)
assert_eq "tmux-flag.sh emits exactly a bell outside tmux" "$(printf '\a')" "$out"
out=$(env -u TMUX_PANE -u TMUX "$UNFLAG" 2>&1)
assert_eq "tmux-unflag.sh emits nothing outside tmux" "" "$out"

echo "test: tmux-flag.sh sets @claude_attn on the target window"
TMUX_PANE="$pane" "$FLAG"
attn=$(tmux show-window-options -t "$SESSION:$win2" -v @claude_attn 2>/dev/null)
assert_eq "@claude_attn set to 1" "1" "$attn"

echo "test: tmux-unflag.sh clears it back to unset"
TMUX_PANE="$pane" "$UNFLAG"
attn=$(tmux show-window-options -t "$SESSION:$win2" -v @claude_attn 2>/dev/null)
assert_eq "@claude_attn unset after clearing" "" "$attn"

echo "test: the after-select-window hook (tmux/tmux.conf) actually clears the flag on switch"
echo "  regression test for: 'set-window-option -t \"#{window_id}\" ...' silently failing"
echo "  with 'no such window: #{window_id}' - the hook command must target the current"
echo "  window implicitly (no -t), not via an unexpanded #{window_id} string."
hook_cmd=$(grep '^set-hook -g after-select-window' "$DOTFILES/tmux/tmux.conf" | sed -E "s/^set-hook -g after-select-window '(.*)'$/\1/")
if [ -z "$hook_cmd" ]; then
  assert_eq "found the after-select-window hook command in tmux.conf" "found" "not found"
else
  tmux set-hook -t "$SESSION" after-select-window "$hook_cmd"
  TMUX_PANE="$pane" "$FLAG"
  tmux select-window -t "$SESSION:$win1"
  tmux select-window -t "$SESSION:$win2"
  # The hook sets @claude_attn to the string "0" (not unset) - tmux's
  # #{?...} ternary treats "0" as falsy same as empty, so both count as
  # "cleared" for rendering purposes.
  rendered=$(tmux display-message -p -t "$SESSION:$win2" "#{?@claude_attn,ON,off}")
  assert_eq "@claude_attn renders as off after switching to the window" "off" "$rendered"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
