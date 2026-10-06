#!/usr/bin/env bash
# Flags the current tmux window and rings the bell, matching Claude's behavior.
# Skip the flag only when the current window is actively visible to a client.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pane="$("$script_dir/tmux-pane-id.sh")"
if [ -n "$pane" ]; then
  active=$(tmux display-message -p -t "$pane" '#{window_active}')
  attached=$(tmux display-message -p -t "$pane" '#{session_attached}')
  if [ "$active" != "1" ] || [ "$attached" = "0" ]; then
    tmux set-window-option -t "$pane" @codex_attn 1
  fi
fi
printf '\a'
