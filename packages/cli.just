# packages/cli.just — CLI tool installation

# Install all CLI tools
install-cli:
    #!/usr/bin/env bash
    set -euo pipefail

    OS="{{OS}}"
    DISTRO="{{DISTRO}}"

    if [ "$OS" = "Darwin" ] || [ "$DISTRO" = "arch" ]; then
        echo "Installing CLI tools via: {{INSTALL_CMD}}"
        {{INSTALL_CMD}} starship eza bat zoxide fzf jq tmux neovim fish kubectl terraform
    else
        # Ubuntu: apt handles what it has, cargo handles the rest
        source "$HOME/.cargo/env" 2>/dev/null || true
        echo "Installing CLI tools via apt..."
        sudo apt-get install -y bat fzf jq tmux fish zsh kubectl terraform

        # bat: apt installs as batcat on Ubuntu — fix the name
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
            echo "  linked bat -> batcat"
        fi

        # starship, eza, zoxide — Rust tools, install via cargo
        {{CARGO_INSTALL_CMD}} starship eza zoxide

        # neovim — apt version is ancient, use AppImage
        if ! command -v nvim &>/dev/null; then
            echo "Installing neovim..."
            curl -Lo /tmp/nvim.appimage \
                https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
            chmod u+x /tmp/nvim.appimage
            sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
        else
            echo "  skip   neovim (already installed)"
        fi
    fi

    echo "CLI tools installed."

# Install oh-my-zsh and zsh plugins
install-zsh:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh..."
        RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "  skip   oh-my-zsh (already installed)"
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
        echo "  skip   zsh-autosuggestions (already installed)"
    fi

    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        echo "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting \
            "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    else
        echo "  skip   zsh-syntax-highlighting (already installed)"
    fi

    echo "zsh plugins installed."

# Set up fish: register in /etc/shells, set as default shell, refresh conf.d caches
install-fish:
    #!/usr/bin/env bash
    set -euo pipefail

    FISH_PATH="$(command -v fish || true)"
    if [ -z "$FISH_PATH" ]; then
        echo "fish not found — run 'just install-cli' first"
        exit 1
    fi

    # 1. Register fish in /etc/shells (required by chsh)
    if ! grep -qxF "$FISH_PATH" /etc/shells; then
        echo "Adding $FISH_PATH to /etc/shells (requires sudo)..."
        echo "$FISH_PATH" | sudo tee -a /etc/shells >/dev/null
    else
        echo "  skip   $FISH_PATH already in /etc/shells"
    fi

    # 2. Make fish the default login shell
    if [ "${SHELL:-}" != "$FISH_PATH" ]; then
        echo "Setting fish as default shell (requires your password)..."
        chsh -s "$FISH_PATH"
        echo "  Default shell changed. Open a new terminal to apply."
    else
        echo "  skip   fish already default shell"
    fi

    # 3. Refresh cached tool-init files (starship, zoxide)
    #    These live in shell/fish/conf.d and are committed; regenerate if you
    #    upgrade starship/zoxide.
    echo "Refreshing fish conf.d caches..."
    DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd 2>/dev/null || echo "$HOME/.dotfiles")"
    CONF_D="$DOTFILES/shell/fish/conf.d"

    if command -v starship &>/dev/null; then
        starship init fish --print-full-init > "$CONF_D/starship_init.fish"
        echo "  updated starship_init.fish"
    fi

    if command -v zoxide &>/dev/null; then
        zoxide init fish > "$CONF_D/zoxide_init.fish"
        echo "  updated zoxide_init.fish"
    fi

    # 4. Refresh kubectl aliases from upstream
    echo "Refreshing kubectl aliases..."
    curl -fsSL https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases.fish \
        -o "$CONF_D/kubectl_aliases.fish"
    echo "  updated kubectl_aliases.fish ($(wc -l < "$CONF_D/kubectl_aliases.fish") lines)"

    echo ""
    echo "fish setup complete. Open a new terminal (or 'exec fish') to start using it."

# Bootstrap tmux plugin manager
install-tpm:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        echo "Installing TPM..."
        git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
    else
        echo "  skip   TPM (already installed)"
    fi
