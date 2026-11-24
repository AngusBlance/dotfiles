#!/usr/bin/env bash
# Usage: play-sound.sh <filename-in-~/.copilot/sounds/>
sound="$HOME/.copilot/sounds/$1"
( command -v afplay >/dev/null && afplay "$sound" ) || \
( command -v paplay >/dev/null && paplay "$sound" ) || \
( command -v aplay >/dev/null && aplay -q "$sound" ) || \
printf '\a' 2>/dev/null
