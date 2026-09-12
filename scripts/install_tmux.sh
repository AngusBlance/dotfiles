#!/usr/bin/env bash
# tmux (3.1+) reads $XDG_CONFIG_HOME/tmux/tmux.conf directly, so the whole
# directory can be symlinked as-is — no leading-dot filename needed.
install_tmux() {
  link_config "$DOTFILES/tmux" "$HOME/.config/tmux"

  local plugins_dir="$HOME/.config/tmux/plugins"
  mkdir -p "$plugins_dir"

  local already_present=true
  [ -d "$plugins_dir/tpm" ] || { already_present=false; git clone --quiet https://github.com/tmux-plugins/tpm "$plugins_dir/tpm"; }
  # Catppuccin isn't declared via @plugin (it's loaded via a direct `run`
  # line in tmux.conf), so TPM doesn't know to install it - clone it directly.
  [ -d "$plugins_dir/catppuccin" ] || { already_present=false; git clone --quiet https://github.com/catppuccin/tmux.git "$plugins_dir/catppuccin"; }

  if ! "$plugins_dir/tpm/bin/install_plugins" > /dev/null 2>&1; then
    echo "  warning: tmux plugin install failed (check your network?)"
  elif [ "$already_present" = true ]; then
    echo "  tmux plugins already installed"
  else
    echo "  tmux plugins installed"
  fi
}
