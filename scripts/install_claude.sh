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

# Symlinks the synced skills and global CLAUDE.md into ~/.claude, then merges
# claude/settings.shared.json into settings.json. Shared keys override; the
# permission lists are combined (order kept, duplicates dropped) so
# machine-local permissions and every other local setting survive.
install_claude_config() {
  local claude_dir="$HOME/.claude"
  local settings="$claude_dir/settings.json"
  local shared="$DOTFILES/claude/settings.shared.json"

  mkdir -p "$claude_dir"
  link_config "$DOTFILES/claude/skills" "$claude_dir/skills"
  link_config "$DOTFILES/claude/CLAUDE.md" "$claude_dir/CLAUDE.md"

  [ -s "$settings" ] || echo '{}' > "$settings"
  if ! jq -e 'type == "object"' "$settings" > /dev/null 2>&1; then
    echo "  error: $settings is not a JSON object, left unchanged" >&2
    return 1
  fi

  local merged
  # Checked explicitly: without set -e a failed jq would leave merged empty
  # and the write below would wipe settings.json.
  if ! merged=$(jq --slurpfile shared "$shared" '
    def union($a; $b): reduce ($a + $b)[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end);
    . as $cur
    | ($cur * $shared[0])
    | reduce ("allow", "deny", "ask") as $k (.;
        if ($cur.permissions[$k] != null) or ($shared[0].permissions[$k] != null)
        then .permissions[$k] = union($cur.permissions[$k] // []; $shared[0].permissions[$k] // [])
        else . end)
  ' "$settings"); then
    echo "  error: could not merge $shared into $settings, left unchanged" >&2
    return 1
  fi

  if [ "$merged" = "$(jq . "$settings")" ]; then
    echo "  shared settings up to date, skipping"
    return 0
  fi

  # Separate from install_claude_ding's settings.json.bak, which it rewrites every run.
  cp "$settings" "$settings.shared.bak"
  printf '%s\n' "$merged" > "$settings"
  echo "  shared settings merged"
}
