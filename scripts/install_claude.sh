#!/usr/bin/env bash
# Installs the Claude Code hooks from claude/hooks.json, plus the sounds and
# scripts they reference. Merges into settings.json rather than symlinking it,
# since that file holds other settings too.
#
# Upserts by marker (": dotfiles_managed_hook; ..." - a bash no-op prefix, no
# runtime effect) rather than exact command match, so editing a hook's command
# replaces the old entry instead of duplicating it. Hooks without the marker
# (added by hand) are left alone.
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

  local event new_group old_marked_cmd new_cmd
  for event in $(jq -r '.hooks | keys[]' "$hooks_src"); do
    new_group=$(jq --arg e "$event" '.hooks[$e]' "$hooks_src")
    new_cmd=$(echo "$new_group" | jq -r '.[0].hooks[0].command')

    old_marked_cmd=$(jq -r --arg e "$event" \
      '(((.hooks[$e]) // [])[]?.hooks[]? | select(.command | startswith(": dotfiles_managed_hook;")) | .command) // empty' \
      "$settings")

    if [ "$old_marked_cmd" = "$new_cmd" ]; then
      echo "  $event hook up to date, skipping"
      continue
    fi

    jq --arg e "$event" --argjson new "$new_group" '
      .hooks[$e] = (
        ((.hooks[$e] // []) | map(select((.hooks[0].command | startswith(": dotfiles_managed_hook;")) | not)))
        + $new
      )
    ' "$settings" > "$settings.tmp"
    mv "$settings.tmp" "$settings"

    if [ -z "$old_marked_cmd" ]; then
      echo "  $event hook installed"
    else
      echo "  $event hook updated"
    fi
  done
}
