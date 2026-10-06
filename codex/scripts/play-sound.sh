#!/usr/bin/env bash
# Usage: play-sound.sh <filename-in-../sounds/>
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sound="$script_dir/../sounds/$1"
( command -v afplay >/dev/null && afplay "$sound" ) || \
( command -v paplay >/dev/null && paplay "$sound" ) || \
( command -v aplay >/dev/null && aplay -q "$sound" ) || \
printf '\a' 2>/dev/null
