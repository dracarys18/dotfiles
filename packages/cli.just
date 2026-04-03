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
