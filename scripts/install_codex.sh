#!/usr/bin/env bash
# Links the Codex dotfiles directory and merges its managed hooks into
# ~/.codex/hooks.json, preserving hooks that were added outside this repo.
install_codex() {
  local codex_dir="$HOME/.codex"
  local hooks="$codex_dir/hooks.json"
  local hooks_src="$DOTFILES/codex/hooks.json"

  mkdir -p "$codex_dir"
  link_config "$DOTFILES/codex" "$codex_dir/dotfiles"

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

  # Remove obsolete managed adapter hooks from the earlier untracked setup.
  # Keep any unmarked hooks the user added to these event groups.
  local stale_event
  for stale_event in PreCompact PreToolUse SessionStart; do
    if jq -e --arg e "$stale_event" '.hooks[$e] | type == "array"' "$hooks" >/dev/null 2>&1; then
      if ! merged=$(jq --arg e "$stale_event" '
        .hooks[$e] = ((.hooks[$e] // []) | map(select(
          [(.hooks[]?.command // "") | contains("$HOME/.local/share/dotfiles-agent-hooks/agent-hook.sh")] | any | not
        )))
        | if .hooks[$e] == [] then del(.hooks[$e]) else . end
      ' "$hooks"); then
        echo "  error: could not remove obsolete $stale_event hooks from $hooks; file left unchanged" >&2
        return 1
      fi
      if [ "$merged" != "$(jq . "$hooks")" ]; then
        printf '%s\n' "$merged" > "$hooks.tmp"
        mv "$hooks.tmp" "$hooks"
        echo "  obsolete $stale_event adapter hook removed"
      fi
    fi
  done
}
