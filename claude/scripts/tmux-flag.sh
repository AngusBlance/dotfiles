#!/usr/bin/env bash
# Flags the current tmux window (sets @claude_attn=1, read by
# @catppuccin_window_text in tmux/tmux.conf to show a red dot) and rings
# the terminal bell. Called from the Stop and Notification hooks - i.e.
# whenever it's "your move" and Claude is waiting on you. Cleared by
# tmux-unflag.sh (UserPromptSubmit hook) the moment you reply - see
# tests/test-tmux-attention.sh.
#
# Hook wiring based on erikg/claudisms (tmux-attention-bell):
# https://github.com/erikg/claudisms/tree/master/tmux-attention-bell
# (that project uses a plain window-status-style color override for the
# visual, which works on vanilla tmux; it doesn't show through here because
# Catppuccin's window-status-format bakes its own literal colors inside the
# segment, painting over a plain style override - so the visual here is a
# text-prefix via @catppuccin_window_text instead, proven to work with this
# theme.)
if [ -n "${TMUX_PANE:-}" ]; then
  tmux set-window-option -t "$TMUX_PANE" @claude_attn 1
fi
printf '\a'
