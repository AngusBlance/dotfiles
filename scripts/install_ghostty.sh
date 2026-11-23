#!/usr/bin/env bash
# Symlinks this repo's ghostty/ folder to ~/.config/ghostty (read on both
# Linux and macOS). Ghostty is the default terminal: if neither Ghostty nor
# Alacritty is installed, installs Ghostty. If only Alacritty is, leaves it be.
# No font step: Ghostty ships JetBrains Mono and Nerd Font icons built in.
install_ghostty() {
  if has_ghostty; then
    link_config "$DOTFILES/ghostty" "$HOME/.config/ghostty"
    echo "  ghostty already installed"
    return 0
  fi
  if has_alacritty; then
    echo "  ghostty not installed, alacritty is, skipping"
    return 0
  fi

  link_config "$DOTFILES/ghostty" "$HOME/.config/ghostty"

  local cmd
  case "$(uname -s)" in
    Darwin)
      command -v brew > /dev/null 2>&1 && cmd="brew install --cask ghostty"
      ;;
    Linux)
      command -v apt > /dev/null 2>&1 && cmd="sudo apt install -y ghostty"
      ;;
  esac

  if [ -z "${cmd:-}" ]; then
    echo "  warning: no ghostty install method for this system, see https://ghostty.org/download"
    return 0
  fi

  $cmd > /dev/null 2>&1 \
    && echo "  ghostty installed" \
    || echo "  warning: ghostty install failed (tried: $cmd)"
}
