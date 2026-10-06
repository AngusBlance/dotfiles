#!/usr/bin/env bash
# Clears the Codex attention marker when you submit another prompt.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pane="$("$script_dir/tmux-pane-id.sh")"
if [ -n "$pane" ]; then
  tmux set-window-option -u -t "$pane" @codex_attn 2>/dev/null || true
fi
