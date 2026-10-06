#!/usr/bin/env bash
# Resolve the pane running this hook. Codex may remove TMUX/TMUX_PANE from its
# environment, so walk up to the pane's foreground process as a fallback.
set -u

panes="$(tmux list-panes -a -F '#{pane_id} #{pane_pid}' 2>/dev/null)" || exit 0
cwd="$(pwd -P 2>/dev/null)"

# Codex may run hooks through a broker process whose parent chain belongs to a
# different Codex TUI. Accept an ancestry match only when that pane has this
# hook's session working directory.
pid="$PPID"
while [[ "$pid" =~ ^[0-9]+$ ]] && [ "$pid" -gt 1 ]; do
  pane="$(awk -v wanted="$pid" '$2 == wanted { print $1; exit }' <<<"$panes")"
  if [ -n "$pane" ] && [ "$(tmux display-message -p -t "$pane" '#{pane_current_path}' 2>/dev/null)" = "$cwd" ]; then
    printf '%s\n' "$pane"
    exit 0
  fi
  pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d '[:space:]')"
done

# If Codex has stripped its tmux environment, the session cwd usually identifies
# its pane uniquely, even when several tmux windows are running Codex.
matches=""
while read -r pane _; do
  [ -n "$pane" ] || continue
  pane_path="$(tmux display-message -p -t "$pane" '#{pane_current_path}' 2>/dev/null)"
  pane_command="$(tmux display-message -p -t "$pane" '#{pane_current_command}' 2>/dev/null)"
  if [ "$pane_path" = "$cwd" ] && [ "$pane_command" = "codex" ]; then
    matches="${matches}${pane}\n"
  fi
done <<<"$panes"
match_count="$(printf '%b' "$matches" | sed '/^$/d' | wc -l | tr -d '[:space:]')"
if [ "$match_count" = "1" ]; then
  printf '%b' "$matches" | sed '/^$/d'
  exit 0
fi

# An inherited pane is a final fallback, and is trusted only if its directory
# agrees with the Codex hook's working directory.
if [ -n "${TMUX_PANE:-}" ] && grep -Fq "${TMUX_PANE} " <<<"$panes" \
  && [ "$(tmux display-message -p -t "$TMUX_PANE" '#{pane_current_path}' 2>/dev/null)" = "$cwd" ]; then
  printf '%s\n' "$TMUX_PANE"
fi
