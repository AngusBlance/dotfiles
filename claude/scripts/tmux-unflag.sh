#!/usr/bin/env bash
# Clears the flag set by tmux-flag.sh. Called from UserPromptSubmit.
if [ -n "${TMUX_PANE:-}" ]; then
  tmux set-window-option -u -t "$TMUX_PANE" @claude_attn
fi
