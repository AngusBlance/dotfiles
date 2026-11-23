#!/usr/bin/env bash
# Installs the Sioyek PDF viewer and links its user config. Sioyek reads
# ~/.config/sioyek/*_user.config on both Linux and macOS. Linked file-by-file
# rather than the whole dir so anything Sioyek writes there stays untracked.
install_sioyek() {
  link_config "$DOTFILES/sioyek/keys_user.config" "$HOME/.config/sioyek/keys_user.config"

  if command -v sioyek > /dev/null 2>&1; then
    echo "  sioyek already installed"
    return 0
  fi

  local cmd
  case "$(uname -s)" in
    Darwin)
      # The cask also puts a `sioyek` command on PATH, which nvim uses.
      command -v brew > /dev/null 2>&1 && cmd="brew install --cask sioyek"
      ;;
    Linux)
      command -v apt > /dev/null 2>&1 && cmd="sudo apt install -y sioyek"
      ;;
  esac

  if [ -z "${cmd:-}" ]; then
    echo "  warning: no sioyek install method for this system, get it from https://github.com/ahrm/sioyek/releases"
    return 0
  fi

  $cmd > /dev/null 2>&1 \
    && echo "  sioyek installed" \
    || echo "  warning: sioyek install failed (tried: $cmd)"
}
