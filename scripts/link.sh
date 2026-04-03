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

    if [ -e "$dst" ] || [ -L "$dst" ]; then
        echo "  skip   $dst (already exists)"
    else
        ln -s "$src" "$dst"
        echo "  linked $dst -> $src"
    fi
}

echo "Linking dotfiles from $DOTFILES"

# Shell
link "$DOTFILES/shell/.zshrc"        "$HOME/.zshrc"
link "$DOTFILES/shell/starship.toml" "$HOME/.config/starship.toml"
link "$DOTFILES/shell/config.fish"   "$HOME/.config/fish/config.fish"

# Neovim
link "$DOTFILES/nvim" "$HOME/.config/nvim"

# Tmux
link "$DOTFILES/tmux/.tmux.conf" "$HOME/.tmux.conf"

# WezTerm
link "$DOTFILES/wezterm/wezterm.lua"   "$HOME/.config/wezterm/wezterm.lua"
link "$DOTFILES/wezterm/colors"        "$HOME/.config/wezterm/colors"

# macOS-only
if [ "$OS" = "Darwin" ]; then
    link "$DOTFILES/ghostty"      "$HOME/.config/ghostty"
    link "$DOTFILES/yabai/.yabairc" "$HOME/.yabairc"
    link "$DOTFILES/yabai/.skhdrc"  "$HOME/.skhdrc"
fi

echo "Done."
