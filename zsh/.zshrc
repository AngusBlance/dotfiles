# A fish-like zsh. Feature numbers below match plans/zsh-fish-like.md.
#
# ORDER MATTERS in three places, so think before moving blocks:
#   1. brew shellenv must precede compinit  - it prepends brew's site-functions
#      to fpath, and brew-installed completions vanish if compinit runs first.
#   2. zmodload zsh/complist must precede any `bindkey -M menuselect`.
#   3. zsh-syntax-highlighting must load LAST - it wraps every widget that
#      exists at load time; anything defined after it is unwrapped.
#
# DELIBERATELY ABSENT (see the plan for the reasoning):
#   Feature 8  abbreviations      - rebinds space, brittle around isearch/paste
#   Feature 15 command-not-found  - needs a package index to say anything useful
#   Feature 16 terminal title     - we live in tmux; would fight automatic-rename
#   prevd/nextd forward-history   - zsh's pushd is a stack, not a cursor
#   GLOB_STAR_SHORT               - changes ** in sourced scripts too; **/ works
#   setopt CORRECT                - noisy "did you mean" prompts
#   _approximate / _correct       - add Tab latency and guess at intent


#==============================================================================
# SETUP - PATH and editor (not a feature; must come first)
#==============================================================================
# Homebrew: puts brew, and everything brew installs, on PATH. This has to run
# here and not only in .zprofile - .zprofile is read by LOGIN shells only, and a
# non-login shell (Alacritty with an explicit `program`, or any `zsh -i`) would
# otherwise start with no brew, no tmux and no starship.
for _brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
  [ -x "$_brew" ] && eval "$("$_brew" shellenv)" && break
done
unset _brew

# starship's installer drops the binary in /usr/local/bin, which only reaches
# PATH via Apple's path_helper in a login shell - so add it explicitly too.
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
typeset -U path PATH  # drop duplicates, keeping the first occurrence
# fpath needs it too: brew shellenv prepends its site-functions every time it
# runs, so the same directory was listed three times and compinit scanned it
# three times.
typeset -U fpath

export EDITOR="vim"
export VISUAL="$EDITOR"


#==============================================================================
# FEATURE 9 - Auto-cd: typing a directory path changes into it
#==============================================================================
setopt AUTO_CD


#==============================================================================
# FEATURE 17 - Sensible defaults
#==============================================================================
setopt INTERACTIVE_COMMENTS   # allow # comments at the prompt
setopt NO_BEEP
setopt NO_FLOW_CONTROL        # frees Ctrl-S / Ctrl-Q for other uses


#==============================================================================
# FEATURE 14 - Recursive ** globbing
#==============================================================================
# zsh does **/ natively; EXTENDED_GLOB adds ^negation, (#i) etc.
setopt EXTENDED_GLOB


#==============================================================================
# FEATURE 7 - Shared, deduplicated history
#==============================================================================
HISTFILE="$ZDOTDIR/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY
# Append as each command finishes, rather than SHARE_HISTORY's live interleave:
# with many tmux panes open, each pane keeps its own Up-arrow history while
# everything still lands in the one shared file.
setopt INC_APPEND_HISTORY_TIME
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE      # leading space keeps a command out of history
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY            # expand !! into the buffer instead of running it


#==============================================================================
# FEATURE 3 - Tab completion: interactive, arrow-navigable menu with descriptions
#==============================================================================
zmodload zsh/complist         # provides the menuselect keymap (see keybinds)
autoload -Uz compinit
compinit -d "$ZDOTDIR/.zcompdump"

setopt AUTO_LIST
setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# LS_COLORS is unset by default on macOS, which silently made the list-colors
# style below a no-op - completion menus came out uncoloured.
: ${LS_COLORS:="di=34:ln=36:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"}
export LS_COLORS

# Complete dotfiles without having to type the leading dot, so `source <Tab>`
# offers .venv/ and `cd <Tab>` offers .config/. Scoped to the completion system
# on purpose: a global `setopt GLOB_DOTS` would also make `rm *` and `cp *`
# match dotfiles, which is a much bigger and more dangerous change.
_comp_options+=(globdots)

zstyle ':completion:*' menu select
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{blue}%B%d%b%f'
# Describe flags, not just group headings: `git commit -<Tab>` lists --amend
# with what it does beside it. auto-description fills in a generic line for
# options whose completer gives no text of its own.
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
# A visible gutter between a candidate and its description.
zstyle ':completion:*' list-separator '  ·'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' completer _expand _complete


#==============================================================================
# FEATURE 4 - Case-insensitive and partial-word completion matching
#==============================================================================
# Tried in order: exact, case-folded, partial words split on . _ -, substring.
zstyle ':completion:*' matcher-list \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'


#==============================================================================
# FEATURE 10 - Directory history (partial: a stack, not back/forward)
#==============================================================================
setopt AUTO_PUSHD             # every cd pushes onto the stack
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
# `dirs -v` lists it, `cd -<n>` jumps to an entry. cdh picks interactively.
cdh() {
  local dir
  dir=$(dirs -pl | sort -u | fzf --height 40% --reverse) || return
  cd "${dir/#\~/$HOME}"
}


#==============================================================================
# KEYBINDINGS - emacs keymap, which is where Alt-. and Alt-H already live
#==============================================================================
bindkey -e

#--- FEATURE 5 - Up/Down search history filtered by what is already typed -----
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
[[ -n ${terminfo[kcuu1]} ]] && bindkey "${terminfo[kcuu1]}" up-line-or-beginning-search
[[ -n ${terminfo[kcud1]} ]] && bindkey "${terminfo[kcud1]}" down-line-or-beginning-search

#--- FEATURE 1 (keys) - Alt-Right accepts one word of the autosuggestion ------
# Right and Ctrl-F accept the whole thing already: both are forward-char, which
# is in the plugin's default accept-widget list, so they need no binding here.
# forward-word is in its partial-accept list. Two encodings: Alacritty sends
# the first, several other terminals the second.
bindkey '^[[1;3C' forward-word
bindkey '^[^[[C'  forward-word

#--- FEATURE 11 - Alt-E / Ctrl-X Ctrl-E edit the command line in $EDITOR ------
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
bindkey '^[e'  edit-command-line

#--- FEATURE 12 - Alt-H / F1 open the man page for the command being typed ----
# zsh aliases run-help to plain `man` by default, so the alias has to go first.
# The run-help-* helpers understand subcommands (`git rebase` -> git-rebase(1)).
(( ${+aliases[run-help]} )) && unalias run-help
autoload -Uz run-help run-help-git run-help-ssh run-help-sudo
[[ -n ${terminfo[kf1]} ]] && bindkey "${terminfo[kf1]}" run-help

#--- FEATURE 13 - Alt-. inserts the last argument of the previous command -----
# Already bound in the emacs keymap; repeated presses walk back through history.
bindkey '^[.' insert-last-word

#--- FEATURE 3 (keys) - Shift-Tab walks the completion menu backwards ---------
# Requires zmodload zsh/complist, done in the FEATURE 3 block above.
bindkey -M menuselect '^[[Z' reverse-menu-complete


#==============================================================================
# ALIASES
#==============================================================================
alias ls='ls --color=auto'
alias ll='ls -lh'
alias la='ls -lAh'
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'


#==============================================================================
# TMUX - redraw the status bar right after cd
#==============================================================================
# Without this the path and git pills wait for the next status-interval tick,
# up to 5s away. Unchanged from the existing config.
if [[ -n $TMUX ]]; then
  autoload -Uz add-zsh-hook
  _tmux_status_refresh() { tmux refresh-client -S 2>/dev/null }
  add-zsh-hook chpwd _tmux_status_refresh
fi


#==============================================================================
# FEATURE 6 - Ctrl-R interactive history search (also Ctrl-T files, Alt-C cd)
#==============================================================================
# Homebrew keeps these under $HOMEBREW_PREFIX/opt/fzf/shell, Debian under
# /usr/share/doc/fzf/examples.
#
# completion.zsh rebinds Tab to fzf-completion, which looks alarming next to
# FEATURE 3's menu, but the two coexist: with no `**` trigger on the word
# fzf-completion falls straight through to expand-or-complete, so the second
# Tab still enters menu selection and the arrow keys work. Verified by hand.
# Keeping it buys the `**<Tab>` fuzzy trigger (`vim **<Tab>`, `cd **<Tab>`).
#
# Note the menu needs Tab TWICE: the first completes the common prefix and
# lists, the second enters the arrow-navigable menu. That is stock zsh
# behaviour with AUTO_LIST, not something fzf causes.
for _dir in "${HOMEBREW_PREFIX:-/nonexistent}/opt/fzf/shell" /usr/share/doc/fzf/examples; do
  if [ -d "$_dir" ]; then
    [ -f "$_dir/completion.zsh" ]   && source "$_dir/completion.zsh"
    [ -f "$_dir/key-bindings.zsh" ] && source "$_dir/key-bindings.zsh"
    break
  fi
done
unset _dir


#==============================================================================
# FEATURES 1 & 2 - Autosuggestions, then syntax highlighting (MUST BE LAST)
#==============================================================================
# Prefer the pinned clones in $ZDOTDIR/plugins (installed by
# zsh/install-plugins.sh); fall back to system packages so a half-installed
# machine still gets a working shell.
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20   # no suggestions on very long lines

# main      commands valid/invalid, paths, quotes, options, redirections
# brackets  matched pairs coloured by depth, unmatched ones red
# pattern   whole-phrase matches, used for the rm -rf guard below
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern)

# Catppuccin Latte, the same hex values tmux.conf uses, so the shell and the
# status bar read as one theme. Worth overriding rather than leaving alone:
# the plugin's defaults assume a dark terminal, and four of them - quotes,
# reserved words and redirections - are plain `yellow`, which on Latte's
# near-white background is close to unreadable.
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#d20f39,bold'          # red
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#8839ef'               # mauve
ZSH_HIGHLIGHT_STYLES[command]='fg=#40a02b'                     # green
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#40a02b'
ZSH_HIGHLIGHT_STYLES[function]='fg=#40a02b'
ZSH_HIGHLIGHT_STYLES[alias]='fg=#40a02b'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=#40a02b,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=#4c4f69,underline'              # text
ZSH_HIGHLIGHT_STYLES[globbing]='fg=#1e66f5'                    # blue
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#df8e1d'      # yellow
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#df8e1d'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=#fe640b'                 # peach
ZSH_HIGHLIGHT_STYLES[comment]='fg=#8c8fa1'                     # overlay1
ZSH_HIGHLIGHT_STYLES[assign]='fg=#4c4f69'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=#df8e1d'      # $'...' strings
ZSH_HIGHLIGHT_STYLES[bracket-level-4]='fg=#179299'             # teal, was yellow

for _plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  for _base in "$ZDOTDIR/plugins" "${HOMEBREW_PREFIX:-/nonexistent}/share" /usr/share; do
    if [ -f "$_base/$_plugin/$_plugin.zsh" ]; then
      source "$_base/$_plugin/$_plugin.zsh"
      break
    fi
  done
done
unset _plugin _base

# A destructive-command guard: rm -rf and friends get a red block behind them,
# so a mistyped path is visible before Enter rather than after.
#
# Set AFTER the plugin loads, and never pre-declared here: the pattern
# highlighter declares ZSH_HIGHLIGHT_PATTERNS as an ASSOCIATIVE array, so
# declaring it as a normal one above gets silently re-declared and emptied.
if (( ${+ZSH_HIGHLIGHT_PATTERNS} )); then
  ZSH_HIGHLIGHT_PATTERNS+=('rm -rf *' 'fg=#eff1f5,bold,bg=#d20f39')
  ZSH_HIGHLIGHT_PATTERNS+=('rm -fr *' 'fg=#eff1f5,bold,bg=#d20f39')
fi


#==============================================================================
# PROMPT - starship (unchanged)
#==============================================================================
command -v starship > /dev/null 2>&1 && eval "$(starship init zsh)"
