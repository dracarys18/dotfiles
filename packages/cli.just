# packages/cli.just — CLI tool installation

# Install all CLI tools
install-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "Installing CLI tools via: {{INSTALL_CMD}}"
    {{INSTALL_CMD}} starship eza bat zoxide fzf jq tmux neovim fish kubectl terraform

    # Ubuntu-only: fix bat binary name (apt installs it as batcat)
    if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
        echo "  linked bat -> batcat"
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
