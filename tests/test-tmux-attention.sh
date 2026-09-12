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

echo "test: tmux-flag.sh does NOT suppress just because window_active is true"
echo "  regression test for a false-negative bug: a window is 'active' within its own"
echo "  session even when that session has NO client attached at all (e.g. Claude"
echo "  finishes in a background session nobody is viewing). Checking window_active"
echo "  alone would wrongly suppress the flag in exactly that case - the fix requires"
echo "  BOTH window_active AND session_attached > 0 before suppressing."
tmux select-window -t "$SESSION:$win2"
attached=$(tmux display-message -p -t "$SESSION:$win2" '#{session_attached}')
assert_eq "sanity check: this throwaway session really has no attached client" "0" "$attached"
out=$(TMUX_PANE="$pane" "$FLAG" 2>&1)
attn=$(tmux show-window-options -t "$SESSION:$win2" -v @claude_attn 2>/dev/null)
assert_eq "@claude_attn IS set even though window_active is true, since nothing is attached" "1" "$attn"
assert_eq "bell still fires" "$(printf '\a')" "$out"

echo "test: tmux-flag.sh DOES suppress when a real client is attached and viewing it"
echo "  uses a control-mode (-C) tmux client, which counts as a genuine attached"
echo "  client (#{session_attached} > 0) without needing an interactive terminal."
TMUX_PANE="$pane" "$UNFLAG"
ctlpipe=$(mktemp -u)
mkfifo "$ctlpipe"
(tmux -C attach-session -t "$SESSION" < "$ctlpipe" > /dev/null 2>&1 &)
exec 4>"$ctlpipe"
sleep 0.3
attached=$(tmux display-message -p -t "$SESSION:$win2" '#{session_attached}')
if [ "$attached" = "0" ]; then
  echo "  SKIP - could not get a control-mode client to attach in this environment"
else
  tmux select-window -t "$SESSION:$win2"
  out=$(TMUX_PANE="$pane" "$FLAG" 2>&1)
  # Note: select-window above also fires the *global* after-select-window
  # hook from the real tmux.conf (it's -g, shared across every session on
  # this server), which independently sets @claude_attn to "0" - same
  # falsy-render check as the other tests, rather than asserting raw empty.
  rendered=$(tmux display-message -p -t "$SESSION:$win2" "#{?@claude_attn,ON,off}")
  assert_eq "@claude_attn renders as off: window is active AND a client is genuinely attached" "off" "$rendered"
  assert_eq "bell still fires even when suppressing the flag" "$(printf '\a')" "$out"
fi
exec 4>&-
rm -f "$ctlpipe"
tmux select-window -t "$SESSION:$win1"

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

echo "test: the client-session-changed hook clears the flag on a cross-SESSION switch"
echo "  regression test for a real gap: after-select-window only fires when switching"
echo "  windows WITHIN a session - switching to a different session entirely (e.g. via"
echo "  the tmux-sessionx binding this repo uses) doesn't touch it, so a flagged window"
echo "  in another session you switch to would never clear without this second hook."
session_hook_cmd=$(grep '^set-hook -g client-session-changed' "$DOTFILES/tmux/tmux.conf" | sed -E "s/^set-hook -g client-session-changed '(.*)'$/\1/")
if [ -z "$session_hook_cmd" ]; then
  assert_eq "found the client-session-changed hook command in tmux.conf" "found" "not found"
else
  SESSION2="dotfiles_test_attn2_$$"
  tmux new-session -d -s "$SESSION2" -x 80 -y 24
  ctlpipe=$(mktemp -u)
  mkfifo "$ctlpipe"
  (tmux -C attach-session -t "$SESSION" < "$ctlpipe" > /dev/null 2>&1 &)
  exec 4>"$ctlpipe"
  sleep 0.3
  client_name=$(tmux list-clients -t "$SESSION" -F '#{client_name}' | head -1)
  if [ -z "$client_name" ]; then
    echo "  SKIP - could not get a control-mode client to attach in this environment"
  else
    tmux set-hook -t "$SESSION" client-session-changed "$session_hook_cmd"
    tmux set-hook -t "$SESSION2" client-session-changed "$session_hook_cmd"
    # Set the flag directly (not via tmux-flag.sh) - this test is about the
    # clearing hook specifically, not flag.sh's own suppression logic
    # (covered separately above), and an earlier test's control-mode client
    # may still be lingering attached here, which would otherwise confound it.
    tmux set-window-option -t "$SESSION:$win2" @claude_attn 1
    attn_before=$(tmux show-window-options -t "$SESSION:$win2" -v @claude_attn 2>/dev/null)
    tmux switch-client -c "$client_name" -t "$SESSION2"
    sleep 0.2
    tmux switch-client -c "$client_name" -t "$SESSION"
    sleep 0.2
    rendered=$(tmux display-message -p -t "$SESSION:$win2" "#{?@claude_attn,ON,off}")
    assert_eq "sanity check: flag was actually set before switching sessions" "1" "$attn_before"
    assert_eq "@claude_attn renders as off after switching sessions away and back" "off" "$rendered"
  fi
  exec 4>&-
  rm -f "$ctlpipe"
  tmux kill-session -t "$SESSION2" 2>/dev/null || true
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
