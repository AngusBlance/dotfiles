#!/usr/bin/env bash
#
# ==============================================================================
#  install_claude_ding
# ==============================================================================
#  Installs the Claude Code hooks defined in claude/hooks.json plus every
#  sound file they reference and the shared claude/scripts/*.sh helpers.
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
#
#  UPSERT, not append-if-missing: every command this repo installs is
#  prefixed with a marker (`: dotfiles_managed_hook; ...` — `:` is bash's
#  no-op builtin, so the marker text does nothing at runtime beyond being
#  greppable). Before adding our current hook for an event, we strip out
#  any EXISTING entry for that event carrying the same marker, then add
#  the current one fresh. Hooks WITHOUT the marker (ones you added by hand,
#  outside this repo) are left alone. Without this, re-running install.sh
#  after this repo changes what a hook's command actually does — as
#  opposed to adding a brand new event — would append a second copy
#  alongside the stale one instead of replacing it, since the old and new
#  command strings no longer match each other.
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

  local event new_group old_marked_cmd new_cmd
  for event in $(jq -r '.hooks | keys[]' "$hooks_src"); do
    new_group=$(jq --arg e "$event" '.hooks[$e]' "$hooks_src")
    new_cmd=$(echo "$new_group" | jq -r '.[0].hooks[0].command')

    # Our own previous entry for this event, if any (identified by marker,
    # not by exact command match - the whole point is that it may differ).
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
