export PATH="$HOME/.local/bin:$PATH"
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

# fzf fuzzy completion (Ctrl-R history, Ctrl-T files, Alt-C cd)
# Homebrew (macOS) and apt (Linux/WSL) install these in different places.
for f in /opt/homebrew/opt/fzf/shell/{completion,key-bindings}.zsh \
         /usr/share/doc/fzf/examples/{completion,key-bindings}.zsh; do
  [ -f "$f" ] && source "$f"
done

# Autosuggestions: try history first, then fall back to the completion system
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Plugins (syntax-highlighting must be sourced last)
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for dir in /opt/homebrew/share /usr/share; do
    [ -f "$dir/$plugin/$plugin.zsh" ] && source "$dir/$plugin/$plugin.zsh" && break
  done
done

eval "$(starship init zsh)"
