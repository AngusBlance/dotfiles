#!/usr/bin/env bash
#
# ==============================================================================
#  install_claude_ding
# ==============================================================================
#  Installs the Claude Code hooks defined in claude/hooks.json (currently:
#  Stop -> ding.wav, Notification -> waiting.wav) plus every sound file they
#  reference and the shared claude/scripts/play-sound.sh player.
#
#  Unlike the other install_* scripts, this one doesn't use link_config —
#  ~/.claude/settings.json is a single JSON file holding a bunch of your
#  OTHER settings too (theme, permissions, hooks you've added by hand), so
#  symlinking the whole file would mean the repo owns settings it has no
#  business owning. Instead this function reads, merges, and writes back —
#  it never blindly overwrites the file, and merges one hook EVENT at a
#  time (Stop, Notification, ...) so adding a new event to hooks.json is
#  the only thing a future you needs to do — this loop picks it up
#  automatically.
# ==============================================================================
install_claude_ding() {
  local claude_dir="$HOME/.claude"
  local settings="$claude_dir/settings.json"
  local hooks_src="$DOTFILES/claude/hooks.json"

  mkdir -p "$claude_dir/sounds" "$claude_dir/scripts"
  cp "$DOTFILES"/claude/sounds/*.wav "$claude_dir/sounds/"
  cp "$DOTFILES"/claude/scripts/*.sh "$claude_dir/scripts/"
  chmod +x "$claude_dir"/scripts/*.sh

  [ -f "$settings" ] || echo '{}' > "$settings"
  cp "$settings" "$settings.bak"

  # One event (Stop, Notification, ...) at a time: check whether THIS
  # event's exact command is already installed, and if not, append it —
  # same idempotent read/merge/write pattern as before, just parameterized
  # by $event instead of hardcoded to "Stop".
  local event cmd
  for event in $(jq -r '.hooks | keys[]' "$hooks_src"); do
    cmd=$(jq -r --arg e "$event" '.hooks[$e][0].hooks[0].command' "$hooks_src")

    if jq -e --arg e "$event" --arg cmd "$cmd" \
        '((.hooks[$e]) // [])[]?.hooks[]? | select(.type == "command" and .command == $cmd)' \
        "$settings" > /dev/null 2>&1; then
      echo "  $event hook already installed, skipping"
    else
      jq --arg e "$event" --slurpfile new "$hooks_src" \
        '.hooks[$e] = ((.hooks[$e] // []) + $new[0].hooks[$e])' \
        "$settings" > "$settings.tmp"
      mv "$settings.tmp" "$settings"
      echo "  $event hook installed"
    fi
  done
}
