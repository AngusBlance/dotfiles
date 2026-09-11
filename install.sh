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
#  HOW IT'S ORGANIZED
#    This file itself does almost nothing — it just finds the repo, loads
#    every scripts/install_*.sh, and calls each one in order. All the actual
#    work (and the comments explaining it) lives in scripts/. That split
#    keeps this top-level file readable as a table of contents: glance at
#    the bottom of this file and you know exactly what a fresh machine ends
#    up with, without wading through nvim/tmux/zsh/claude details to find
#    that out.
#
#  SAFE TO RE-RUN
#    Every installer below is written to be *idempotent* — running it five
#    times has the same effect as running it once. That matters because you
#    WILL re-run this (after pulling repo updates, after a typo, whatever),
#    and a script that duplicates work or corrupts state on a second run is
#    a trap.
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
# called. Every scripts/install_*.sh below relies on this same variable, so
# the whole repo is portable to any clone location.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Load the installers -------------------------------------------------------
# `source`-ing a file runs it in the CURRENT shell rather than a subshell,
# which is what lets scripts/install_nvim.sh (for example) define a function
# called `install_nvim` that this script can then call directly, and what
# lets every scripts/*.sh see the $DOTFILES variable set above without it
# needing to be passed around explicitly. Sourcing a file only DEFINES the
# functions inside it — nothing actually runs until we call them ourselves,
# below.
source "$DOTFILES/scripts/lib.sh"
for installer in "$DOTFILES"/scripts/install_*.sh; do
  source "$installer"
done

# ==============================================================================
#  Entry point — the actual table of contents
# ==============================================================================
# This is the one place in the whole repo where you can see, at a glance,
# every piece of the machine this bootstraps. Adding a new tool later is
# "write scripts/install_<tool>.sh, add one line here" — nothing about the
# rest of this file needs to change.
echo "== nvim ==";      install_nvim
echo "== tmux ==";      install_tmux
echo "== alacritty =="; install_alacritty
echo "== zsh ==";       install_zsh
echo "== claude ==";    install_claude_ding

echo
echo "Done. Restart your shell (or 'exec zsh') to pick up zsh changes."
