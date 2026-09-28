#!/usr/bin/env bash
# Clones the two zsh plugins into $ZDOTDIR/plugins at a pinned tag.
#
# Pinned rather than tracking master so an update is a deliberate edit here
# rather than a surprise the next time install.sh runs. The versions below are
# the same ones Homebrew currently ships, so this changes no behaviour.
#
# .zshrc looks in $ZDOTDIR/plugins first and falls back to the Homebrew and
# distro paths, so a machine where this script has not run still gets a working
# shell - just an unpinned one.
set -euo pipefail

ZSH_PLUGIN_PINS=(
  "zsh-autosuggestions|https://github.com/zsh-users/zsh-autosuggestions|v0.7.1"
  "zsh-syntax-highlighting|https://github.com/zsh-users/zsh-syntax-highlighting|0.8.0"
)

install_zsh_plugins() {
  local plugins_dir="${ZDOTDIR:-$HOME/.config/zsh}/plugins"
  mkdir -p "$plugins_dir"

  local entry name url tag dir current
  for entry in "${ZSH_PLUGIN_PINS[@]}"; do
    IFS='|' read -r name url tag <<< "$entry"
    dir="$plugins_dir/$name"

    if [ ! -d "$dir/.git" ]; then
      # Not a clone (missing, or a stale plain directory) - start fresh.
      rm -rf "$dir"
      if git clone --quiet --depth 1 --branch "$tag" "$url" "$dir" 2>/dev/null; then
        echo "  $name: cloned at $tag"
      else
        echo "  warning: $name clone failed (network?); .zshrc will fall back to the system copy"
      fi
      continue
    fi

    current="$(git -C "$dir" describe --tags --exact-match 2>/dev/null || echo "")"
    if [ "$current" = "$tag" ]; then
      echo "  $name: already at $tag"
      continue
    fi

    # A --depth 1 clone has no other tags, so fetch the one we want by name.
    if git -C "$dir" fetch --quiet --depth 1 origin "refs/tags/$tag:refs/tags/$tag" 2>/dev/null \
       && git -C "$dir" checkout --quiet "$tag" 2>/dev/null; then
      echo "  $name: updated to $tag"
    else
      echo "  warning: $name could not move to $tag (left at ${current:-unknown})"
    fi
  done
}

# Allow running this file directly as well as sourcing it from install_zsh.sh.
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  install_zsh_plugins
fi
