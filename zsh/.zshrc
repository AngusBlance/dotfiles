# Homebrew: puts brew, and everything brew installs, on PATH.
# This has to run here and not only in .zprofile - .zprofile is read by LOGIN
# shells only, and a non-login shell (Alacritty with an explicit `program`, or
# any `zsh -i`) would otherwise start with no brew, no tmux and no starship.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
done
unset _brew

# starship's installer drops the binary in /usr/local/bin, which only reaches
# PATH via Apple's path_helper in a login shell - so add it explicitly too.
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
typeset -U path PATH  # drop duplicates, keeping the first occurrence

export EDITOR="vim"
export VISUAL="$EDITOR"

# History
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY
setopt SHARE_HISTORY

# Useful options
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt CORRECT
setopt INTERACTIVE_COMMENTS
setopt NO_BEEP

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'

# Completion
autoload -Uz compinit
compinit -d "$ZDOTDIR/.zcompdump"

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' completer _expand _complete _correct _approximate

setopt AUTO_LIST
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# fzf fuzzy completion (Ctrl-R history, Ctrl-T files, Alt-C cd).
# Homebrew keeps these under $HOMEBREW_PREFIX/opt/fzf/shell, Debian under
# /usr/share/doc/fzf/examples.
for _dir in "${HOMEBREW_PREFIX:-/nonexistent}/opt/fzf/shell" /usr/share/doc/fzf/examples; do
  if [ -d "$_dir" ]; then
    [ -f "$_dir/completion.zsh" ]   && source "$_dir/completion.zsh"
    [ -f "$_dir/key-bindings.zsh" ] && source "$_dir/key-bindings.zsh"
    break
  fi
done
unset _dir

# Autosuggestions: try history first, then fall back to the completion system
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Plugins - Homebrew installs to $HOMEBREW_PREFIX/share, Debian/Arch to
# /usr/share. Listed in load order: syntax-highlighting must be sourced last.
for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for _base in "${HOMEBREW_PREFIX:-/nonexistent}/share" /usr/share; do
    if [ -f "$_base/$_plugin/$_plugin.zsh" ]; then
      source "$_base/$_plugin/$_plugin.zsh"
      break
    fi
  done
done
unset _plugin _base

# In tmux, redraw the status bar right after cd so the path and git pills
# update now instead of on the next status-interval tick (up to 5s).
if [[ -n $TMUX ]]; then
  autoload -Uz add-zsh-hook
  _tmux_status_refresh() { tmux refresh-client -S 2>/dev/null }
  add-zsh-hook chpwd _tmux_status_refresh
fi

command -v starship > /dev/null 2>&1 && eval "$(starship init zsh)"
