#!/usr/bin/env bash
# Flags the current tmux window (sets @claude_attn=1, read by
# @catppuccin_window_text in tmux/tmux.conf to show a small blue dot) and
# rings the terminal bell. Called from the Stop and Notification hooks -
# i.e. whenever it's "your move" and Claude is waiting on you. Cleared by
# tmux-unflag.sh (UserPromptSubmit hook) or by switching to the window (see
# tmux/tmux.conf's after-select-window / client-session-changed hooks) - see
# tests/test-tmux-attention.sh.
#
# Skips flagging (but still rings the bell) only if you are DEMONSTRABLY
# looking at this exact window right now: it must be the active window of
# its session (#{window_active}) AND that session must actually have a
# client attached (#{session_attached} > 0). Checking window_active alone is
# a false-negative trap: a window is "active" within its own session even
# when that session has no attached client at all (e.g. Claude finishes in
# a background session nobody is viewing) - window_active alone would
# wrongly suppress the flag in exactly the case a persistent indicator
# exists for. Matches the intent of the same check in
# claude-contrib/claude-extensions' tmux-notify plugin (_tmux_is_active_pane):
# https://github.com/claude-contrib/claude-extensions/tree/main/plugins/tmux-notify
# (that plugin only checks window_active; this repo's tests reproduce the
# false-negative with a real control-mode-attached client, which is why the
# session_attached check was added here.)
#
# Hook wiring otherwise based on erikg/claudisms (tmux-attention-bell):
# https://github.com/erikg/claudisms/tree/master/tmux-attention-bell
# (that project uses a plain window-status-style color override for the
# visual, which works on vanilla tmux; it doesn't show through here because
# Catppuccin's window-status-format bakes its own literal colors inside the
# segment, painting over a plain style override - so the visual here is a
# text-prefix via @catppuccin_window_text instead, proven to work with this
# theme.)
if [ -n "${TMUX_PANE:-}" ]; then
  active=$(tmux display-message -p -t "$TMUX_PANE" '#{window_active}')
  attached=$(tmux display-message -p -t "$TMUX_PANE" '#{session_attached}')
  if [ "$active" != "1" ] || [ "$attached" = "0" ]; then
    tmux set-window-option -t "$TMUX_PANE" @claude_attn 1
  fi
fi
printf '\a'
