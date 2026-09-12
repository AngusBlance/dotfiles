#!/usr/bin/env bash
# Usage: play-sound.sh <filename-in-~/.claude/sounds/>
sound="$HOME/.claude/sounds/$1"
( command -v afplay >/dev/null && afplay "$sound" ) || \
( command -v paplay >/dev/null && paplay "$sound" ) || \
( command -v aplay >/dev/null && aplay -q "$sound" ) || \
printf '\a' 2>/dev/null
