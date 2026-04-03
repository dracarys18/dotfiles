# packages/node.just — Node.js via nvm

# Install nvm and Node.js LTS 20
install-node:
    #!/usr/bin/env bash
    set -euo pipefail

    NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

    # Install nvm if not present
    if [ ! -d "$NVM_DIR" ]; then
        echo "Installing nvm..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/HEAD/install.sh | bash
    else
        echo "  skip   nvm (already installed)"
    fi

    # Load nvm for this script
    export NVM_DIR="$NVM_DIR"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    # Install Node 20
    if ! nvm ls 20 &>/dev/null; then
        echo "Installing Node.js 20..."
        nvm install 20
        nvm alias default 20
    else
        echo "  skip   node@20 (already installed)"
    fi

    echo "Node.js installed."
