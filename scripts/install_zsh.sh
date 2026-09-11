#!/usr/bin/env bash
#
# zsh has an unusual startup quirk this has to work around: ~/.zshenv is
# the ONE file zsh always reads first, no matter what — before it even
# knows about $ZDOTDIR. Every other rc file (.zshrc, etc.) is then read
# from $ZDOTDIR instead of $HOME, once .zshenv has had a chance to set it.
#
# This repo's .zshenv sets ZDOTDIR="$HOME/.config/zsh", so:
#   - .zshenv itself must be linked at the fixed path ~/.zshenv
#   - everything else lands inside ~/.config/zsh
#
# We link individual files here rather than symlinking the whole
# ~/.config/zsh directory, because zsh also WRITES real, machine-specific
# junk into that same directory at runtime (.zsh_history, .zcompdump) —
# files we deliberately do not want ending up inside the git repo. Linking
# file-by-file keeps ~/.config/zsh as a real directory that mixes tracked
# (symlinked) files with untracked local ones.
install_zsh() {
  link_config "$DOTFILES/zsh/.zshenv" "$HOME/.zshenv"
  link_config "$DOTFILES/zsh/.zshrc" "$HOME/.config/zsh/.zshrc"
  link_config "$DOTFILES/zsh/dependancies.sh" "$HOME/.config/zsh/dependancies.sh"
}
