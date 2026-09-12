#!/usr/bin/env bash
# ~/.zshenv is fixed (zsh reads it before ZDOTDIR exists); it sets
# ZDOTDIR=~/.config/zsh, where everything else lives. Linked file-by-file
# rather than the whole dir, since zsh also writes real junk there
# (.zsh_history, .zcompdump) that shouldn't be tracked.
install_zsh() {
  link_config "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
  link_config "$DOTFILES/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"

  if command -v starship > /dev/null 2>&1; then
    echo "  starship already installed"
  else
    curl -sS https://starship.rs/install.sh | sh -s -- --yes > /dev/null 2>&1 \
      && echo "  starship installed" \
      || echo "  warning: starship install failed"
  fi
}
