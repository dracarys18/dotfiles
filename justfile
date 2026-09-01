import 'packages/cli.just'
import 'packages/rust.just'
import 'packages/go.just'
import 'packages/node.just'
import 'packages/fonts.just'
import 'packages/macos.just'
import 'prerequisites/prerequisites.just'

# Detect OS and distro once — used by all imported recipes
OS     := `uname -s`
DISTRO := `[ -f /etc/os-release ] && grep -i "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"' | tr '[:upper:]' '[:lower:]' || echo ""`

# Single install command passed to every recipe
INSTALL_CMD       := if OS == "Darwin"   { "brew install" } \
               else if DISTRO == "arch" { "sudo pacman -S --noconfirm --needed" } \
               else                     { "sudo apt-get install -y" }

CARGO_INSTALL_CMD := "cargo install"

# List all available recipes
default:
    @just --list

# Full one-time setup: prerequisites → packages → symlinks
install: prerequisites install-rust install-cli install-zsh install-fish install-tpm install-go install-node install-fonts install-macos link
    @echo ""
    @echo "Setup complete. Restart your shell to apply changes."

# Create all config symlinks (skips existing)
link:
    @bash scripts/link.sh

# Create only the pi coding-agent symlinks (extensions, agents, prompts)
pi-link:
    @bash scripts/pilink.sh

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
    remove_link "$HOME/.config/fish/conf.d"
    remove_link "$HOME/.config/nvim"
    remove_link "$HOME/.tmux.conf"
    remove_link "$HOME/.config/wezterm/wezterm.lua"
    remove_link "$HOME/.config/wezterm/colors"

    # pi coding agent
    remove_link "$HOME/.pi/agent/extensions/plan-mode"
    remove_link "$HOME/.pi/agent/extensions/subagent"
    remove_link "$HOME/.pi/agent/extensions/todo.ts"
    remove_link "$HOME/.pi/agent/extensions/permission-gate.ts"
    remove_link "$HOME/.pi/agent/extensions/protected-paths.ts"
    remove_link "$HOME/.pi/agent/agents/planner.md"
    remove_link "$HOME/.pi/agent/agents/reviewer.md"
    remove_link "$HOME/.pi/agent/agents/scout.md"
    remove_link "$HOME/.pi/agent/agents/worker.md"
    remove_link "$HOME/.pi/agent/prompts/implement.md"
    remove_link "$HOME/.pi/agent/prompts/implement-and-review.md"
    remove_link "$HOME/.pi/agent/prompts/scout-and-plan.md"
    remove_link "$HOME/.pi/agent/keybindings.json"

    # pi skills (dynamic: iterate over pi/skills/*, skipping README)
    if [ -d "pi/skills" ]; then
        for entry in pi/skills/*; do
            [ -e "$entry" ] || continue
            name="$(basename "$entry")"
            case "$name" in README.md|readme.md) continue ;; esac
            remove_link "$HOME/.pi/agent/skills/$name"
        done
    fi

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
