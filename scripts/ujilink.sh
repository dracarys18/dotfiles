#!/usr/bin/env bash
# ujilink.sh — set up the uji coding agent on a fresh machine.
# Idempotent: skips what is already in place, backs up anything in the way.
#
# The tracked config lives under <dotfiles>/uji and is linked to ~/.config/uji.
# The source checkouts are cloned under ~/Projects: uji itself, the plugin
# collection, and the skills, which live apart so other agents can read them.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECTS="${UJI_PROJECTS:-$HOME/Projects}"

UJI_URL="${UJI_URL:-git@github.com:uji-labs/uji.git}"
PLUGINS_URL="${UJI_PLUGINS_URL:-git@github.com:uji-labs/uji-plugins.git}"
SKILLS_URL="${UJI_SKILLS_URL:-git@github.com:uji-labs/uji-skills.git}"

link() {
    local src="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
        echo "  skip   $dst (already linked)"
        return
    fi
    if [ -e "$dst" ] || [ -L "$dst" ]; then
        mv "$dst" "${dst}.bak"
        echo "  backup $dst -> ${dst}.bak"
    fi
    ln -s "$src" "$dst"
    echo "  linked $dst -> $src"
}

# Clone into <projects>/<name>, leaving an existing checkout untouched so local
# work is never clobbered.
clone() {
    local name="$1"
    local url="$2"
    local dst="$PROJECTS/$name"
    if [ -d "$dst/.git" ]; then
        echo "  skip   $dst (already cloned)"
        return 0
    fi
    if [ -e "$dst" ]; then
        echo "  warn   $dst exists but is not a git checkout — leaving it alone"
        return 0
    fi
    mkdir -p "$PROJECTS"
    if git clone "$url" "$dst"; then
        echo "  cloned $dst"
    else
        echo "  failed $url — clone it by hand, then rerun"
        return 1
    fi
}

need() {
    command -v "$1" >/dev/null 2>&1 || { echo "  missing $1 — $2"; return 0; }
    echo "  found  $1"
}

echo "Checking what uji needs"
need git "required to fetch the repos"
need curl "required: web search and page fetching shell out to it"
need node "required: the web-search skill scripts are node"
need cargo "required to build uji"
need npx "optional: needed only for MCP servers published to npm"
need uvx "optional: needed only for MCP servers published to PyPI"

echo "Cloning into $PROJECTS"
clone uji "$UJI_URL" || true
clone uji-plugins "$PLUGINS_URL" || true
clone uji-skills "$SKILLS_URL" || true

echo "Linking uji config from $DOTFILES/uji"
link "$DOTFILES/uji" "$HOME/.config/uji"

echo "Binary"
if [ -d "$PROJECTS/uji/crates/uji" ]; then
    cargo install --path "$PROJECTS/uji/crates/uji" --locked
    echo "  installed uji"
else
    echo "  skip   no checkout at $PROJECTS/uji"
fi

echo
echo "Done. Set the keys uji needs in your shell profile:"
echo "  LITELLM_BASE_URL, LITELLM_API_KEY   the provider in uji/plugin/litellm.lua"
echo "  BRAVE_API_KEY                       optional; web search falls back to DuckDuckGo"
