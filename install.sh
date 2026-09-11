#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
