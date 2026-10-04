mac_flake := justfile_directory() / "src/mac/nix#mac"
nix := "/nix/var/nix/profiles/default/bin/nix --extra-experimental-features 'nix-command flakes'"

# List recipes
default:
    @just --list

# Set up a fresh machine: `just bootstrap mac`
bootstrap os:
    @{{ just_executable() }} bootstrap-{{ os }}

[private]
bootstrap-mac:
    #!/usr/bin/env bash
    set -euo pipefail
    [ "$(uname -s)" = Darwin ] || { echo "not a Mac" >&2; exit 1; }
    echo "Sign in to the App Store first if you haven't: the switch installs App Store apps."
    sudo -v

    if [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
        echo "==> Installing Nix"
        sh <(curl --proto '=https' --tlsv1.2 -sSfL https://nixos.org/nix/install) --daemon --yes
    fi

    if [ ! -x /opt/homebrew/bin/brew ]; then
        echo "==> Installing Homebrew"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    export PATH="/opt/homebrew/bin:$PATH"

    if [ -x /run/current-system/sw/bin/darwin-rebuild ]; then
        sudo darwin-rebuild switch --flake "{{ mac_flake }}"
    else
        # The Nix installer edits these; nix-darwin refuses to overwrite files it
        # doesn't recognise, so set them aside (it restores them on uninstall)
        for f in bashrc zshrc shells; do
            if [ -e "/etc/$f" ] && [ ! -L "/etc/$f" ]; then
                sudo mv "/etc/$f" "/etc/$f.before-nix-darwin"
            fi
        done
        echo "==> First switch"
        sudo {{ nix }} run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake "{{ mac_flake }}"
    fi

    cat <<'EOF'

    Done. Log out and back in so every app picks up the new shell. Then by hand:
      - yabai scripting addition: Recovery Mode -> Terminal ->
        `csrutil enable --without debug --without fs`, reboot, `sudo yabai --load-sa`
      - open Firefox once, then `just switch` to link its config
      - optional: `bash scripts/ujilink.sh` once GitHub SSH keys are set up
    EOF

# Apply the repo to this Mac
switch:
    sudo darwin-rebuild switch --flake "{{ mac_flake }}"

# Update packages, nvim plugins and treesitter parsers, then switch
update:
    {{ nix }} flake update --flake "{{ justfile_directory() }}/src/mac/nix"
    sudo darwin-rebuild switch --flake "{{ mac_flake }}"
    nvim --headless "+lua vim.pack.update(nil, { force = true })" +qa
    nvim --headless "+lua require('nvim-treesitter').update():wait(300000)" +qa

# Undo the last switch
rollback:
    sudo darwin-rebuild --rollback

# Delete old generations and free disk space
clean:
    sudo nix-collect-garbage -d
    sudo nix store optimise

# Save OBS settings into the repo (stream keys and logins blanked)
obs-save:
    bash src/mac/scripts/obs-save.sh
