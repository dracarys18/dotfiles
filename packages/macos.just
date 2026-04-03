# packages/macos.just — macOS-only tools (yabai, skhd, ghostty, wezterm)

# Install macOS window manager and terminal tools
install-macos:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ "{{OS}}" != "Darwin" ]; then
        echo "  skip   macOS-only tools (not on macOS)"
        exit 0
    fi

    # yabai — tiling window manager
    if brew list yabai &>/dev/null; then
        echo "  skip   yabai (already installed)"
    else
        echo "Installing yabai..."
        brew install koekeishiya/formulae/yabai
    fi

    # skhd — hotkey daemon
    if brew list skhd &>/dev/null; then
        echo "  skip   skhd (already installed)"
    else
        echo "Installing skhd..."
        brew install koekeishiya/formulae/skhd
    fi

    # ghostty — terminal emulator
    if brew list --cask ghostty &>/dev/null; then
        echo "  skip   ghostty (already installed)"
    else
        echo "Installing ghostty..."
        brew install --cask ghostty
    fi

    echo ""
    echo "  [MANUAL] yabai scripting addition requires SIP to be partially disabled."
    echo "  If you haven't done this yet:"
    echo ""
    echo "    1. Boot into Recovery Mode -> Utilities -> Terminal"
    echo "    2. Run: csrutil enable --without debug --without fs"
    echo "    3. Reboot, then run: sudo yabai --load-sa"
    echo ""
    echo "macOS tools installed."
