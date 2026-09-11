#!/usr/bin/env bash
# tmux (3.1+) reads $XDG_CONFIG_HOME/tmux/tmux.conf directly, so the whole
# directory can be symlinked as-is — no leading-dot filename needed.
install_tmux() {
  link_config "$DOTFILES/tmux" "$HOME/.config/tmux"
}
