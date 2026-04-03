# packages/go.just — Go toolchain and go tools

# Install Go and go-based tools
install-go:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v go &>/dev/null; then
        echo "Installing Go via: {{INSTALL_CMD}}"
        {{INSTALL_CMD}} go
    else
        echo "  skip   go (already installed)"
    fi

    export PATH="$PATH:$(go env GOPATH)/bin"

    if ! command -v gopls &>/dev/null; then
        echo "Installing gopls..."
        go install golang.org/x/tools/gopls@latest
    else
        echo "  skip   gopls (already installed)"
    fi

    echo "Go tools installed."
