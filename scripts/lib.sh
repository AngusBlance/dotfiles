#!/usr/bin/env bash
# Shared helpers for the per-tool installers in this scripts/ directory.

# link_config <repo-source-path> <home-target-path>
# Symlinks target -> source. Backs up an existing real file/dir at target
# to "target.pre-dotfiles.bak" first. No-op if already correctly linked.
link_config() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ] && [ "$(readlink -f "$target")" = "$(readlink -f "$source")" ]; then
    echo "  already linked: $target"
    return 0
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    local backup="$target.pre-dotfiles.bak"
    echo "  backing up existing $target -> $backup"
    rm -rf "$backup"
    mv "$target" "$backup"
  fi

  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  echo "  linked: $target -> $source"
}
