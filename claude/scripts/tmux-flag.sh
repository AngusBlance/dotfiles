#!/usr/bin/env bash
# Flags the current tmux window and rings the bell. Called from Stop/Notification.
# Skips the flag (bell still fires) only if you're demonstrably looking at this
# window right now: active AND its session has a client attached - window_active
# alone is a false-negative trap for background sessions nobody's viewing.
if [ -n "${TMUX_PANE:-}" ]; then
  active=$(tmux display-message -p -t "$TMUX_PANE" '#{window_active}')
  attached=$(tmux display-message -p -t "$TMUX_PANE" '#{session_attached}')
  if [ "$active" != "1" ] || [ "$attached" = "0" ]; then
    tmux set-window-option -t "$TMUX_PANE" @claude_attn 1
  fi
fi
printf '\a'
