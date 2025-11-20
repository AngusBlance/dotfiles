#!/usr/bin/env bash

# Print the given path with $HOME replaced by ~ so the statusline stays concise.
set -euo pipefail

raw_path="${1:-.}"

if [[ -n "${HOME:-}" && "${raw_path}" == "${HOME}"* ]]; then
  printf '~%s' "${raw_path#"$HOME"}"
else
  printf '%s' "${raw_path}"
fi
