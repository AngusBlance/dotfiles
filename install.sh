#!/usr/bin/env bash
#
# ==============================================================================
#  install.sh — dotfiles bootstrap
# ==============================================================================
#
#  PURPOSE
#    Make this repo reproduce itself on a brand-new machine. The idea behind
#    "dotfiles as a repo" is: everything that makes your environment *yours*
#    (configs, hooks, sounds) lives in version control instead of only on
#    disk, so a new laptop is one `git clone` + one script away from feeling
#    like home.
#
#  USAGE
#    git clone git@github.com:AngusBlance/dotfiles.git
#    ./dotfiles/install.sh
#
#  SAFE TO RE-RUN
#    Every step below is written to be *idempotent* — running it five times
#    has the same effect as running it once. That matters because you WILL
#    re-run this (after pulling repo updates, after a typo, whatever), and a
#    script that duplicates work or corrupts state on a second run is a trap.
#
# ==============================================================================

# --- Shell safety flags -------------------------------------------------------
# By default, bash is very forgiving: it happily continues after a failed
# command, silently treats an unset variable as an empty string, and — worst
# of all — swallows failures in the middle of a pipeline. `set -euo pipefail`
# turns all three of those off, so that a mistake fails LOUDLY instead of
# quietly doing the wrong thing:
#   -e          exit immediately if any command exits non-zero
#   -u          treat use of an undefined variable as an error
#   -o pipefail a pipeline (a | b | c) fails if ANY stage fails, not just
#               the last one
set -euo pipefail

# --- Where am I? ---------------------------------------------------------------
# A classic gotcha: you can't assume the script is being *run from* the
# directory it lives in (someone might `cd /elsewhere && ~/dotfiles/install.sh`).
# So instead of relying on the current directory, we ask bash where THIS
# script file actually is:
#   ${BASH_SOURCE[0]}   the path to this very script, as invoked
#   dirname ...         strip the filename, leaving just the containing folder
#   cd ... && pwd        resolve that into a full, absolute, symlink-free path
# The result — DOTFILES — is the repo root, no matter how the script was
# called. Every other path in this file is built relative to it, so the
# whole script is portable to any clone location.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ==============================================================================
#  install_claude_ding
# ==============================================================================
#  What this installs: a Claude Code "Stop" hook — a shell command Claude
#  Code runs every time it finishes responding — that plays a short sound.
#  See ../README.md and claude/hooks.json for the human-readable version of
#  what gets merged in.
#
#  The tricky part isn't playing a sound; it's installing this WITHOUT
#  clobbering whatever else already lives in ~/.claude/settings.json (theme,
#  permissions, other hooks you've added by hand). So this function reads,
#  merges, and writes back — it never blindly overwrites the file.
# ==============================================================================
install_claude_ding() {
  # Local variable names, scoped to this function only (the `local` keyword).
  # Without `local`, these would leak into the global shell namespace — fine
  # in a 5-line script, a real liability once a script grows more functions.
  local sound_src="$DOTFILES/claude/sounds/ding.wav"   # the WAV we ship in-repo
  local hooks_src="$DOTFILES/claude/hooks.json"        # the hook definition we ship in-repo
  local claude_dir="$HOME/.claude"                     # Claude Code's per-user config dir
  local settings="$claude_dir/settings.json"           # the file we're carefully editing

  # Step 1: get the actual sound file onto disk where the hook expects it.
  # `mkdir -p` creates parent directories as needed AND doesn't complain if
  # the directory already exists — that's what makes this line idempotent.
  mkdir -p "$claude_dir/sounds"
  cp "$sound_src" "$claude_dir/sounds/ding.wav"

  # Step 2: make sure settings.json exists at all before we try to read it.
  # This is a "guard clause": `[ -f "$settings" ]` tests "does this file
  # exist?"; `||` means "and if that test FAILED, do the following instead".
  # So: if the file is missing, seed it with an empty JSON object so the
  # `jq` calls below have something valid to parse.
  [ -f "$settings" ] || echo '{}' > "$settings"

  # Step 3: back up before mutating. Cheap insurance — if anything below
  # goes wrong, or you decide you hated this whole idea, `settings.json.bak`
  # is your one-line escape hatch (`mv settings.json.bak settings.json`).
  cp "$settings" "$settings.bak"

  # Step 4: pull the exact hook *command string* out of hooks.json, so we
  # can check "is this specific hook already installed?" a moment from now.
  # `jq -r` = "run this jq filter, and print the Raw string result (no
  # surrounding quotes)". The filter `.hooks.Stop[0].hooks[0].command` walks
  # the JSON structure: hooks -> Stop -> [first entry] -> hooks -> [first
  # entry] -> command. It mirrors the exact shape of claude/hooks.json —
  # open that file side-by-side if this indexing looks opaque.
  local cmd
  cmd=$(jq -r '.hooks.Stop[0].hooks[0].command' "$hooks_src")

  # Step 5: the idempotency check. Before adding anything, ask: does a Stop
  # hook with THIS EXACT command already exist in the user's settings.json?
  #   jq -e   exit with status 0 if the filter produces any output, 1 if it
  #           produces nothing — perfect for using jq as an `if` condition
  #   --arg cmd "$cmd"   safely pass the shell variable into the jq filter
  #           as $cmd, without worrying about quoting/escaping bugs (never
  #           interpolate a shell variable directly into a jq filter string)
  #   (.hooks.Stop // [])   "give me .hooks.Stop, or an empty array if that
  #           path doesn't exist yet" — the `//` is jq's "fallback" operator,
  #           and it's what lets this run safely on a settings.json that has
  #           no `hooks` key at all
  #   []?.hooks[]?   the trailing `?` means "if this key/index doesn't
  #           exist, produce nothing instead of throwing an error" — so a
  #           weirdly-shaped existing entry can't crash the whole script
  #   select(.type == "command" and .command == $cmd)   keep only entries
  #           that are an exact match for the hook we're about to install
  if jq -e --arg cmd "$cmd" \
      '(.hooks.Stop // [])[]?.hooks[]? | select(.type == "command" and .command == $cmd)' \
      "$settings" > /dev/null 2>&1; then
    # Already there from a previous run — say so and do nothing further.
    # This is the "idempotent" branch: re-running the script is a safe no-op.
    echo "claude: Stop-hook ding already installed, skipping"
  else
    # Not installed yet — merge it in.
    #   --slurpfile new hooks.json   read the WHOLE hooks.json file and bind
    #           it to the jq variable $new (as an array containing one
    #           element, hence the `$new[0]` below)
    #   .hooks.Stop = ((.hooks.Stop // []) + $new[0].hooks.Stop)
    #           take whatever Stop hooks already exist (or [] if none), and
    #           APPEND ours to the end — this is what preserves any other
    #           Stop hooks you've configured by hand, instead of replacing
    #           the whole array
    # Notice we redirect to a `.tmp` file rather than editing settings.json
    # directly. jq cannot safely read and write the *same* file in one
    # command (it can truncate the file to empty before it's finished
    # reading it) — write-to-temp-then-`mv` is the standard safe pattern for
    # "edit a file in place" with any streaming tool.
    jq --slurpfile new "$hooks_src" \
      '.hooks.Stop = ((.hooks.Stop // []) + $new[0].hooks.Stop)' \
      "$settings" > "$settings.tmp"
    mv "$settings.tmp" "$settings"
    echo "claude: Stop-hook ding installed"
  fi
}

# ==============================================================================
#  Entry point
# ==============================================================================
# Everything above this line just *defines* the function — nothing runs
# until it's actually called. As the repo grows (nvim, tmux, alacritty,
# zsh...) this is the spot where you'd add one line per config, e.g.
# `install_nvim`, `install_tmux`, each following the same
# "read what's there, merge, don't clobber" philosophy as the function above.
install_claude_ding
