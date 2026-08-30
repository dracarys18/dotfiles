#!/usr/bin/env bash
# space.sh — go to / send focused window to space $1, creating missing spaces.
# Usage: space.sh <index> focus   -> focus that space
#        space.sh <index> send    -> send focused window there, then follow
set -euo pipefail

idx="$1"
action="${2:-focus}"

if ! [[ "$idx" =~ ^[0-9]+$ ]] || [ "$idx" -lt 1 ]; then
    echo "space.sh: index must be a positive integer" >&2
    exit 1
fi

# Create spaces until the (global mission-control) index exists.
count=$(yabai -m query --spaces | jq 'length')
while [ "$count" -lt "$idx" ]; do
    yabai -m space --create
    count=$((count + 1))
done

case "$action" in
    send) yabai -m window --space "$idx" && yabai -m space --focus "$idx" ;;
    focus) yabai -m space --focus "$idx" ;;
    *) echo "space.sh: unknown action '$action'" >&2; exit 1 ;;
esac
