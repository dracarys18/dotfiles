# packages/fonts.just — Nerd Font installation

# Install Hasklug (Hasklig) Nerd Font
install-fonts:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ "{{OS}}" = "Darwin" ]; then
        echo "Tapping homebrew/cask-fonts..."
        brew tap homebrew/cask-fonts 2>/dev/null || true

        if brew list --cask font-hasklug-nerd-font &>/dev/null; then
            echo "  skip   font-hasklug-nerd-font (already installed)"
        else
            echo "Installing Hasklug Nerd Font..."
            brew install --cask font-hasklug-nerd-font
        fi
    else
        echo ""
        echo "  [NOTICE] Hasklug Nerd Font is not in the official Arch repos."
        echo "  Install it manually via AUR:"
        echo ""
        echo "    yay -S otf-hasklig-nerd"
        echo "  or"
        echo "    paru -S otf-hasklig-nerd"
        echo ""
    fi

    echo "Fonts done."
