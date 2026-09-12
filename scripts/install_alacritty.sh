#!/usr/bin/env bash
# Symlinks this repo's alacritty/ folder to ~/.config/alacritty.
install_alacritty() {
  link_config "$DOTFILES/alacritty" "$HOME/.config/alacritty"
}
