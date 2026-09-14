#!/usr/bin/env bash

# catppuccin-friendly gitmux wrapper that strips branch prefixes and the
# trailing colour reset (it would cut off the pill background).
set -euo pipefail

dir="${1:-.}"

command -v gitmux >/dev/null 2>&1 || exit 0

gitmux -cfg "$HOME/.config/tmux/gitmux.conf" "$dir" | sed -E 's#(⎇ )[^ ]*/#\1#; s# [^ ]*/[^ ]*##; s/#\[fg=default,bg=default\]//g'
