# packages/go.just — Go toolchain and go tools

# Install Go and go-based tools
install-go:
    #!/usr/bin/env bash
    set -euo pipefail
    OS="$(uname -s)"

    # Install Go itself
    if ! command -v go &>/dev/null; then
        echo "Installing Go..."
        if [ "$OS" = "Darwin" ]; then
            brew install go
        elif grep -qi "arch" /etc/os-release 2>/dev/null; then
            sudo pacman -S --noconfirm --needed go
        elif grep -qi "ubuntu\|debian" /etc/os-release 2>/dev/null; then
            sudo apt-get update -y
            sudo apt-get install -y golang-go
        fi
    else
        echo "  skip   go (already installed)"
    fi

    # Ensure GOPATH/bin is available for this script
    export PATH="$PATH:$(go env GOPATH)/bin"

    # gopls — Go language server
    if ! command -v gopls &>/dev/null; then
        echo "Installing gopls..."
        go install golang.org/x/tools/gopls@latest
    else
        echo "  skip   gopls (already installed)"
    fi

    echo "Go tools installed."
