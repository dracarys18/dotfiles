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

# Refresh fish conf.d caches (starship init, zoxide init, kubectl aliases)
# Does NOT change your default shell — run `chsh -s $(command -v fish)` yourself
# if you want to make fish the login shell.
install-fish:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v fish &>/dev/null; then
        echo "fish not found — run 'just install-cli' first"
        exit 1
    fi

    DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/.." && pwd 2>/dev/null || echo "$HOME/.dotfiles")"
    CONF_D="$DOTFILES/shell/fish/conf.d"

    # Refresh cached starship init
    if command -v starship &>/dev/null; then
        starship init fish --print-full-init > "$CONF_D/starship_init.fish"
        echo "  updated starship_init.fish"
    fi

    # Refresh cached zoxide init
    if command -v zoxide &>/dev/null; then
        zoxide init fish > "$CONF_D/zoxide_init.fish"
        echo "  updated zoxide_init.fish"
    fi

    # Refresh kubectl aliases from upstream
    echo "Refreshing kubectl aliases..."
    curl -fsSL https://raw.githubusercontent.com/ahmetb/kubectl-aliases/master/.kubectl_aliases.fish \
        -o "$CONF_D/kubectl_aliases.fish"
    echo "  updated kubectl_aliases.fish ($(wc -l < "$CONF_D/kubectl_aliases.fish") lines)"

    echo ""
    echo "fish caches refreshed. To make fish your default shell, run:"
    echo "  echo \"\$(command -v fish)\" | sudo tee -a /etc/shells"
    echo "  chsh -s \"\$(command -v fish)\""

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
