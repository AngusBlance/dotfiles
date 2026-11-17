#!/bin/bash
# Claude Code status line: dir, git branch, model, plan usage (5h + 7d).
input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
five=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at // empty')
week=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // empty')

out=""
sep=" $(printf '\033[2m·\033[0m') "
# Remaining percentage from a used_percentage value, rounded, never below 0.
left() { awk -v u="$1" 'BEGIN { l = 100 - u; if (l < 0) l = 0; printf "%.0f", l }'; }
add() { if [ -n "$out" ]; then out="$out$sep$1"; else out="$1"; fi; }

# Directory (no PS1 was found in shell config, so use a plain basename)
[ -n "$cwd" ] && add "$(printf '\033[36m%s\033[0m' "$(basename "$cwd")")"

# Git branch (skip optional locks)
if [ -n "$cwd" ]; then
  branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$cwd" symbolic-ref --short HEAD 2>/dev/null)
  [ -n "$branch" ] && add "$(printf '\033[32m%s\033[0m' "$branch")"
fi

[ -n "$model" ] && add "$model"

# 5-hour usage with local reset time
if [ -n "$five" ]; then
  seg="5h: $(left "$five")% left"
  if [ -n "$five_reset" ]; then
    t=$(date -r "${five_reset%.*}" +%H:%M 2>/dev/null)
    [ -n "$t" ] && seg="$seg · resets $t"
  fi
  add "$seg"
fi

# Weekly usage
[ -n "$week" ] && add "7d: $(left "$week")% left"

printf '%s\n' "$out"
