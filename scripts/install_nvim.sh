#!/usr/bin/env bash
# Symlinks this repo's nvim/ folder to ~/.config/nvim, and installs
# ImageMagick, which snacks.image needs to show any image that isn't a PNG.
install_nvim() {
  link_config "$DOTFILES/nvim" "$HOME/.config/nvim"

  if command -v magick > /dev/null 2>&1 || command -v convert > /dev/null 2>&1; then
    echo "  imagemagick already installed"
    return 0
  fi

  local cmd
  case "$(uname -s)" in
    Darwin) command -v brew > /dev/null 2>&1 && cmd="brew install imagemagick" ;;
    Linux)  command -v apt > /dev/null 2>&1 && cmd="sudo apt install -y imagemagick" ;;
  esac

  if [ -z "${cmd:-}" ]; then
    echo "  warning: install ImageMagick yourself so nvim can show non-PNG images"
    return 0
  fi

  $cmd > /dev/null 2>&1 \
    && echo "  imagemagick installed" \
    || echo "  warning: imagemagick install failed (tried: $cmd)"
}
