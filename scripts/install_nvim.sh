#!/usr/bin/env bash
# Symlinks this repo's nvim/ folder to ~/.config/nvim.
install_nvim() {
  link_config "$DOTFILES/nvim" "$HOME/.config/nvim"
}
