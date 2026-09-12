#!/usr/bin/env bash
# ~/.zshenv is fixed (zsh reads it before ZDOTDIR exists); it sets
# ZDOTDIR=~/.config/zsh, where everything else lives. Linked file-by-file
# rather than the whole dir, since zsh also writes real junk there
# (.zsh_history, .zcompdump) that shouldn't be tracked.
install_zsh() {
  link_config "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
  link_config "$DOTFILES/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
  link_config "$DOTFILES/zsh/dependancies.sh" "$HOME/.config/zsh/dependancies.sh"
}
