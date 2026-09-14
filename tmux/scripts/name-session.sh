#!/usr/bin/env bash

# Rename a numbered session after the folder it started in. Adds -2, -3, ...
# when that name is already taken, instead of silently keeping the number.
set -euo pipefail

session_id="$1"
name="$(basename "${2:-session}")"
# tmux turns . and : into _ in session names; do it up front so the
# has-session check compares like with like.
name="${name//[.:]/_}"

candidate="$name"
n=2
while tmux has-session -t "=$candidate" 2>/dev/null; do
  candidate="$name-$n"
  n=$((n + 1))
done

tmux rename-session -t "$session_id" -- "$candidate"
