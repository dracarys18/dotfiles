#!/usr/bin/env bash
# pilink.sh — link pi dotfiles (extensions, agents, prompts, skills) into
# ~/.pi/agent, and merge curated settings (packages, prefs).
# Idempotent: skips silently if already linked, backs up existing files.
#
# The tracked source lives under <dotfiles>/pi and mirrors the ~/.pi/agent
# layout:
#   pi/extensions/...  -> ~/.pi/agent/extensions/...
#   pi/agents/...      -> ~/.pi/agent/agents/...
#   pi/prompts/...     -> ~/.pi/agent/prompts/...
#   pi/skills/...      -> ~/.pi/agent/skills/...
#
# `pi/settings.json` is a curated source: its `packages` array is merged
# (union) into the live `~/.pi/agent/settings.json`. Pi's own auto-managed
# fields (e.g. `lastChangelogVersion`) are preserved.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_SRC="$DOTFILES/pi"
PI_DST="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

merge_pi_settings() {
    local src="$1"
    local dst="$2"

    # Use python3 (stdlib only, no deps) for a safe JSON merge.
    python3 "$(dirname "${BASH_SOURCE[0]}")/pi-merge-settings.py" "$src" "$dst"
}

link() {
    local src="$1"
    local dst="$2"

    # Create parent directory if needed
    mkdir -p "$(dirname "$dst")"

    # Already points to the right place — nothing to do
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  skip   $dst (already linked)"
        return
    fi

    # Exists but is not our symlink — back it up
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "${dst}.bak"
        echo "  backup $dst -> ${dst}.bak"
    fi

    ln -s "$src" "$dst"
    echo "  linked $dst -> $src"
}

echo "Linking pi dotfiles from $PI_SRC"

# Extensions: link each extension directory/file
if [ -d "$PI_SRC/extensions" ]; then
    for entry in "$PI_SRC"/extensions/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$entry")"
        link "$entry" "$PI_DST/extensions/$name"
    done
fi

# Agents: link each .md agent definition
if [ -d "$PI_SRC/agents" ]; then
    for entry in "$PI_SRC"/agents/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$entry")"
        link "$entry" "$PI_DST/agents/$name"
    done
fi

# Prompts: link each .md prompt template
if [ -d "$PI_SRC/prompts" ]; then
    for entry in "$PI_SRC"/prompts/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$entry")"
        link "$entry" "$PI_DST/prompts/$name"
    done
fi

# Skills: link each skill directory (each contains a SKILL.md)
# Skip README.md and any non-skill helpers at the top level.
if [ -d "$PI_SRC/skills" ]; then
    for entry in "$PI_SRC"/skills/*; do
        [ -e "$entry" ] || continue
        name="$(basename "$entry")"
        case "$name" in
            README.md|readme.md) continue ;;
        esac
        link "$entry" "$PI_DST/skills/$name"
    done
fi

# Settings: merge curated `packages` (and prefs) into the live settings.json.
# The live file is NOT symlinked — pi mutates it (lastChangelogVersion, etc.).
if [ -f "$PI_SRC/settings.json" ]; then
    merge_pi_settings "$PI_SRC/settings.json" "$PI_DST/settings.json"
fi

echo "Done."
