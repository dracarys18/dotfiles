#!/usr/bin/env bash
# link.sh — create symlinks from dotfiles repo to expected locations
# Idempotent: skips silently if target already exists

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OS="$(uname -s)"

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

echo "Linking dotfiles from $DOTFILES"

# Shell
link "$DOTFILES/shell/.zshrc"          "$HOME/.zshrc"
link "$DOTFILES/shell/starship.toml"   "$HOME/.config/starship.toml"
link "$DOTFILES/shell/fish/config.fish" "$HOME/.config/fish/config.fish"
link "$DOTFILES/shell/fish/conf.d"     "$HOME/.config/fish/conf.d"

# Neovim
link "$DOTFILES/nvim" "$HOME/.config/nvim"

# uji coding agent
link "$DOTFILES/uji" "$HOME/.config/uji"

# Tmux
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

# WezTerm
link "$DOTFILES/wezterm/wezterm.lua"   "$HOME/.config/wezterm/wezterm.lua"
link "$DOTFILES/wezterm/colors"        "$HOME/.config/wezterm/colors"

# Pi coding agent (extensions, agents, prompts)
bash "$DOTFILES/scripts/pilink.sh"

# Firefox (the default-release profile)
if [ "$OS" = "Darwin" ]; then
    FIREFOX_DIR="$HOME/Library/Application Support/Firefox"
else
    FIREFOX_DIR="$HOME/.mozilla/firefox"
fi
FIREFOX_PROFILE=$(awk -F= '
    /^\[/ { if (name == "default-release") print path; name = ""; path = "" }
    $1 == "Name" { name = $2 }
    $1 == "Path" { path = $2 }
    END { if (name == "default-release") print path }
' "$FIREFOX_DIR/profiles.ini" 2>/dev/null | head -1)
if [ -n "$FIREFOX_PROFILE" ]; then
    link "$DOTFILES/firefox/chrome"  "$FIREFOX_DIR/$FIREFOX_PROFILE/chrome"
    link "$DOTFILES/firefox/user.js" "$FIREFOX_DIR/$FIREFOX_PROFILE/user.js"
else
    echo "  skip   firefox (no default-release profile yet, open Firefox once and rerun)"
fi

# macOS-only
if [ "$OS" = "Darwin" ]; then
    link "$DOTFILES/ghostty"      "$HOME/.config/ghostty"
    link "$DOTFILES/vicinae"      "$HOME/.config/vicinae"
    link "$DOTFILES/yabai/yabairc" "$HOME/.yabairc"
    link "$DOTFILES/yabai/skhdrc"  "$HOME/.skhdrc"
fi

echo "Done."
