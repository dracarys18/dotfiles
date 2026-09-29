# packages/macos.just — macOS-only tools (yabai, skhd, ghostty, raycast)

# Install macOS window manager and terminal tools
install-macos:
    #!/usr/bin/env bash
    set -euo pipefail

    if [ "{{OS}}" != "Darwin" ]; then
        echo "  skip   macOS-only tools (not on macOS)"
        exit 0
    fi

    # yabai/skhd live in koekeishiya/formulae; new Homebrew refuses untrusted
    # third-party taps, so tap + trust it first.
    brew tap koekeishiya/formulae
    brew trust koekeishiya/formulae

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

    if brew list --cask raycast &>/dev/null; then
        echo "  skip   raycast (already installed)"
    else
        echo "Installing raycast..."
        brew install --cask raycast
    fi
    defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 \
        "<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>"
    /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    defaults write com.raycast.macos raycastGlobalHotkey -string "Command-49"

    echo ""
    echo "  [MANUAL] yabai scripting addition requires SIP to be partially disabled."
    echo "  If you haven't done this yet:"
    echo ""
    echo "    1. Boot into Recovery Mode -> Utilities -> Terminal"
    echo "    2. Run: csrutil enable --without debug --without fs"
    echo "    3. Reboot, then run: sudo yabai --load-sa"
    echo ""
    echo "macOS tools installed."
