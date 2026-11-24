#!/usr/bin/env bash
# Installs the Copilot hooks from copilot/hooks.json, plus the sounds and scripts
# they reference. This mirrors the managed-hook pattern used by Claude/Codex so
# the terminal can chime when work is done.
install_copilot() {
  local copilot_dir="$HOME/.copilot"
  local hooks="$copilot_dir/hooks.json"
  local hooks_src="$DOTFILES/copilot/hooks.json"

  mkdir -p "$copilot_dir/sounds" "$copilot_dir/scripts"
  cp "$DOTFILES"/claude/sounds/*.wav "$copilot_dir/sounds/"
  cp "$DOTFILES"/copilot/scripts/*.sh "$copilot_dir/scripts/"
  chmod +x "$copilot_dir"/scripts/*.sh

  [ -f "$hooks" ] || printf '{}\n' > "$hooks"
  if ! jq -e 'type == "object" and ((.hooks // {}) | type == "object")' "$hooks" >/dev/null 2>&1; then
    echo "  error: $hooks must be a JSON object with an object-valued hooks key, left unchanged" >&2
    return 1
  fi
  [ -e "$hooks.bak" ] || cp "$hooks" "$hooks.bak"

  local event new_group merged
  while IFS= read -r event; do
    new_group=$(jq --arg e "$event" '.hooks[$e]' "$hooks_src")
    if ! merged=$(jq --arg e "$event" --argjson new "$new_group" '
      .hooks = (.hooks // {})
      | .hooks[$e] = (((.hooks[$e] // []) | map(select((.hooks[0].command // "" | startswith(": dotfiles_managed_hook;")) | not))) + $new)
    ' "$hooks"); then
      echo "  error: could not merge $event hooks into $hooks; file left unchanged" >&2
      return 1
    fi

    if [ "$merged" != "$(jq . "$hooks")" ]; then
      printf '%s\n' "$merged" > "$hooks.tmp"
      mv "$hooks.tmp" "$hooks"
      echo "  $event hooks installed"
    else
      echo "  $event hooks up to date, skipping"
    fi
  done < <(jq -r '.hooks | keys[]' "$hooks_src")
}
