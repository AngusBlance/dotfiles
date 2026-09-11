#!/usr/bin/env bash
#
# Shared helpers for the per-tool installers in this scripts/ directory.
# Sourced by install.sh — not meant to be run directly.

# link_config <repo-source-path> <home-target-path>
#
# Makes <target> a symlink pointing at <source>, the same trick tools like
# GNU Stow use. This is the piece that actually fixes the "edit ~/.config
# and the repo silently drifts apart" problem: once linked, there's only
# ONE copy of the file on disk — the one in this repo — so any edit you
# make while using the tool day-to-day IS an edit to the git repo, with no
# separate "sync back" step required.
#
#   - If <target> is already the correct symlink: no-op (safe to re-run).
#   - If something real already lives at <target> (a plain file or
#     directory from before you adopted this repo): it gets moved aside to
#     "<target>.pre-dotfiles.bak" rather than deleted, so a first run on a
#     machine with an existing hand-made config can't destroy it silently.
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

  # mkdir -p on the PARENT (not the target itself) — the target is about to
  # become a symlink, not a directory, so we only need its containing
  # folder (e.g. ~/.config) to exist first.
  mkdir -p "$(dirname "$target")"
  ln -s "$source" "$target"
  echo "  linked: $target -> $source"
}
