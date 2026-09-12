#!/usr/bin/env bash
# Clears the flag set by tmux-flag.sh. Called from the UserPromptSubmit
# hook - submitting a prompt IS the acknowledgement, so that's where the
# reset belongs (not a timer, not window-switch).
if [ -n "${TMUX_PANE:-}" ]; then
  tmux set-window-option -u -t "$TMUX_PANE" @claude_attn
fi
