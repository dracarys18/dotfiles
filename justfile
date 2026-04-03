import 'packages/cli.just'
import 'packages/rust.just'
import 'packages/go.just'
import 'packages/node.just'
import 'packages/fonts.just'
import 'packages/macos.just'

# List all available recipes
default:
    @just --list

# Full one-time setup: symlinks + all packages
install: link install-cli install-zsh install-tpm install-rust install-go install-node install-fonts install-macos
    @echo ""
    @echo "Setup complete. Restart your shell to apply changes."

# Create all config symlinks (skips existing)
link:
    @bash scripts/link.sh

# Remove all symlinks created by this repo
unlink:
    #!/usr/bin/env bash
    set -euo pipefail
    DOTFILES="$(pwd)"
    OS="$(uname -s)"

    remove_link() {
        local dst="$1"
        if [ -L "$dst" ]; then
            rm "$dst"
            echo "  removed $dst"
        fi
    }

    remove_link "$HOME/.zshrc"
    remove_link "$HOME/.config/starship.toml"
    remove_link "$HOME/.config/fish/config.fish"
    remove_link "$HOME/.config/nvim"
    remove_link "$HOME/.tmux.conf"
    remove_link "$HOME/.config/wezterm/wezterm.lua"
    remove_link "$HOME/.config/wezterm/colors"

    if [ "$OS" = "Darwin" ]; then
        remove_link "$HOME/.config/ghostty"
        remove_link "$HOME/.yabairc"
        remove_link "$HOME/.skhdrc"
    fi

    echo "Symlinks removed."

# Upgrade packages and update neovim plugins + treesitter parsers
update:
    #!/usr/bin/env bash
    set -euo pipefail
    OS="$(uname -s)"

    if [ "$OS" = "Darwin" ]; then
        echo "Upgrading brew packages..."
        brew upgrade
    elif grep -qi "arch" /etc/os-release 2>/dev/null; then
        echo "Upgrading pacman packages..."
        sudo pacman -Syu --noconfirm
    elif grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
        echo "Upgrading apt packages..."
        sudo apt-get update -y && sudo apt-get upgrade -y
    fi

    echo "Updating Neovim plugins..."
    nvim --headless "+Lazy sync" +qa 2>/dev/null || true

    echo "Updating Treesitter parsers..."
    nvim --headless "+TSUpdateSync" +qa 2>/dev/null || true

    echo "Update complete."
