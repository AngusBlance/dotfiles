#!/usr/bin/env bash

# catppuccin-friendly gitmux wrapper that strips branch prefixes.
set -euo pipefail

dir="${1:-.}"

command -v gitmux >/dev/null 2>&1 || exit 0

gitmux -cfg "$HOME/.gitmux.conf" "$dir" | sed -E 's#(⎇ )[^ ]*/#\1#; s# [^ ]*/[^ ]*##'
