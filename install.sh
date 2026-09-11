#!/usr/bin/env bash
# Bootstrap this dotfiles repo onto a fresh machine.
set -euo pipefail
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

install_claude_ding() {
  local sound_src="$DOTFILES/claude/sounds/ding.wav"
  local hooks_src="$DOTFILES/claude/hooks.json"
  local claude_dir="$HOME/.claude"
  local settings="$claude_dir/settings.json"

  mkdir -p "$claude_dir/sounds"
  cp "$sound_src" "$claude_dir/sounds/ding.wav"

  [ -f "$settings" ] || echo '{}' > "$settings"
  cp "$settings" "$settings.bak"

  local cmd
  cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$hooks_src")

  if jq -e --arg cmd "$cmd" \
      '(.hooks.Stop // [])[]?.hooks[]? | select(.type == "command" and .command == $cmd)' \
      "$settings" > /dev/null 2>&1; then
    echo "claude: Stop-hook ding already installed, skipping"
  else
    jq --slurpfile new "$hooks_src" \
      '.hooks.Stop = ((.hooks.Stop // []) + $new[0].hooks.Stop)' \
      "$settings" > "$settings.tmp"
    mv "$settings.tmp" "$settings"
    echo "claude: Stop-hook ding installed"
  fi
}

install_claude_ding
