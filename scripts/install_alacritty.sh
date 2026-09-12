#!/usr/bin/env bash
# Symlinks this repo's alacritty/ folder to ~/.config/alacritty.
install_alacritty() {
  link_config "$DOTFILES/alacritty" "$HOME/.config/alacritty"

  if ! command -v fc-list > /dev/null 2>&1 || ! command -v unzip > /dev/null 2>&1; then
    echo "  warning: fc-list/unzip not found, skipping Nerd Font install (Linux only)"
    return 0
  fi

  # Plain grep, not `grep -q`: -q exits the instant it finds a match, closing
  # the pipe early and killing fc-list with SIGPIPE while it's still writing.
  # Under `set -o pipefail` (which install.sh uses) that poisons the whole
  # pipeline's exit status to non-zero even though grep DID match - this
  # would always report "not installed" and reinstall on every run.
  if fc-list | grep -i "JetBrainsMono Nerd Font" > /dev/null; then
    echo "  JetBrainsMono Nerd Font already installed"
    return 0
  fi

  local fonts_dir="$HOME/.local/share/fonts"
  mkdir -p "$fonts_dir"
  if curl -fsSLo "$fonts_dir/JetBrainsMono.zip" \
      https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.zip \
    && unzip -oq "$fonts_dir/JetBrainsMono.zip" -d "$fonts_dir/JetBrainsMono" \
    && fc-cache -f > /dev/null 2>&1; then
    echo "  JetBrainsMono Nerd Font installed"
  else
    echo "  warning: Nerd Font install failed (check your network?)"
  fi
  rm -f "$fonts_dir/JetBrainsMono.zip"
}
