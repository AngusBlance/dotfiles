#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v git > /dev/null 2>&1; then
  echo "git is required (you need it to have cloned this repo, so this shouldn't happen)." >&2
  exit 1
fi

PACKAGE_MANAGERS=(
  "apt:sudo apt install -y"
  "brew:brew install"
  "pacman:sudo pacman -S --noconfirm"
  "dnf:sudo dnf install -y"
)

if ! command -v jq > /dev/null 2>&1; then
  echo "jq not found, attempting to install it..."
  installed=false
  for entry in "${PACKAGE_MANAGERS[@]}"; do
    pm="${entry%%:*}"
    install_cmd="${entry#*:}"
    if command -v "$pm" > /dev/null 2>&1; then
      $install_cmd jq
      installed=true
      break
    fi
  done
  if [ "$installed" = false ]; then
    echo "Could not detect a package manager - install jq manually, then re-run this script." >&2
    exit 1
  fi
  command -v jq > /dev/null 2>&1 || { echo "jq install failed." >&2; exit 1; }
fi

source "$DOTFILES/scripts/lib.sh"
for installer in "$DOTFILES"/scripts/install_*.sh; do
  source "$installer"
done

echo "== nvim ==";      install_nvim
echo "== tmux ==";      install_tmux
echo "== alacritty =="; install_alacritty
echo "== zsh ==";       install_zsh
echo "== claude ==";    install_claude_ding

echo
echo "Done. Restart your shell (or 'exec zsh') to pick up zsh changes."
