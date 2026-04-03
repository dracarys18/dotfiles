# packages/cli.just — CLI tool installation

# Install all CLI tools
install-cli:
    #!/usr/bin/env bash
    set -euo pipefail
    OS="$(uname -s)"

    PKGS="starship eza bat zoxide fzf jq tmux neovim fish kubectl terraform"

    if [ "$OS" = "Darwin" ]; then
        echo "Installing CLI tools via brew..."
        brew install $PKGS
    elif [ "$OS" = "Linux" ]; then
        # Detect distro
        if grep -qi "arch" /etc/os-release 2>/dev/null; then
            echo "Installing CLI tools via pacman..."
            sudo pacman -S --noconfirm --needed $PKGS
        elif grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
            echo "Installing CLI tools via apt..."
            sudo apt-get update -y
            # apt package names differ slightly
            sudo apt-get install -y zsh tmux jq fzf fish
            # Install starship via official script
            if ! command -v starship &>/dev/null; then
                curl -sS https://starship.rs/install.sh | sh -s -- --yes
            fi
            # Install eza (replaces exa)
            if ! command -v eza &>/dev/null; then
                sudo apt-get install -y gpg
                sudo mkdir -p /etc/apt/keyrings
                wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
                    | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
                echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                    | sudo tee /etc/apt/sources.list.d/gierens.list
                sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
                sudo apt-get update -y
                sudo apt-get install -y eza
            fi
            # Install bat
            if ! command -v bat &>/dev/null; then
                sudo apt-get install -y bat
                # On Ubuntu bat binary may be called batcat
                mkdir -p ~/.local/bin
                ln -sf "$(which batcat)" ~/.local/bin/bat 2>/dev/null || true
            fi
            # Install zoxide
            if ! command -v zoxide &>/dev/null; then
                curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            fi
            # Install neovim (AppImage for latest version)
            if ! command -v nvim &>/dev/null; then
                curl -Lo /tmp/nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage
                chmod u+x /tmp/nvim.appimage
                sudo mv /tmp/nvim.appimage /usr/local/bin/nvim
            fi
            # Install kubectl
            if ! command -v kubectl &>/dev/null; then
                curl -LO "https://dl.k8s.io/release/$(curl -sSL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                rm kubectl
            fi
            # Install terraform
            if ! command -v terraform &>/dev/null; then
                sudo apt-get install -y gnupg software-properties-common
                wget -O- https://apt.releases.hashicorp.com/gpg | \
                    gpg --dearmor | \
                    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
                echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
                    https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
                    sudo tee /etc/apt/sources.list.d/hashicorp.list
                sudo apt-get update -y
                sudo apt-get install -y terraform
            fi
        else
            echo "Unsupported Linux distro. Install CLI tools manually."
            exit 1
        fi
    fi
    echo "CLI tools installed."

# Install oh-my-zsh and zsh plugins
install-zsh:
    #!/usr/bin/env bash
    set -euo pipefail

    # Install oh-my-zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing oh-my-zsh..."
        RUNZSH=no CHSH=no sh -c \
            "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    else
        echo "  skip   oh-my-zsh (already installed)"
    fi

    ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        echo "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    else
        echo "  skip   zsh-autosuggestions (already installed)"
    fi

    # zsh-syntax-highlighting
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
