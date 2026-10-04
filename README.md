# dotfiles

One Mac, described by Nix: nix-darwin handles the system (Nix, login shell,
fonts, Homebrew apps, macOS settings), home-manager handles the user (CLI tools
and the files in `config/`).

| File          | What it holds                                                       |
| ------------- | ------------------------------------------------------------------- |
| `flake.nix`   | Inputs (nixpkgs 26.05, nix-darwin, home-manager) and the host       |
| `darwin.nix`  | System settings and Homebrew casks/taps                              |
| `home.nix`    | CLI packages and which file in `config/` goes where                 |
| `config/`     | The actual config files                                             |
| `scripts/`    | `debloat.sh` (run by darwin.nix), plus extras run by hand (uji, OBS) |

## Day to day

```sh
sudo darwin-rebuild switch --flake ~/dotfiles   # apply changes
nix flake update --flake ~/dotfiles             # bump nixpkgs and friends, then switch
sudo darwin-rebuild --rollback                  # undo the last switch
```

- Add a CLI tool: put it in `home.packages` in `home.nix`, then switch.
- Add a GUI app: put it in `homebrew.casks` in `darwin.nix`, then switch.
  Anything installed with `brew install` and not listed there is removed on the
  next switch.
- Config files are read-only copies in the Nix store. Edit them in
  `~/dotfiles/config`, then switch. `nvim-pack-lock.json` and vicinae's
  `settings.json` are linked straight to the repo, because the apps rewrite them.
- New files must be `git add`ed before switching: flakes only see tracked files.

## Fresh Mac

1. Install Nix: `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)`
2. Install Homebrew from https://brew.sh (nix-darwin manages its packages, not
   Homebrew itself).
3. Clone: `git clone https://github.com/dracarys18/dotfiles.git ~/dotfiles`
4. First switch, before `darwin-rebuild` exists:
   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/dotfiles
   ```
   If it stops on files in `/etc` it doesn't recognise, rename them as it says
   (e.g. `sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin`) and run it again.
5. By hand:
   - yabai scripting addition needs SIP partly off: Recovery Mode → Terminal →
     `csrutil enable --without debug --without fs`, reboot, `sudo yabai --load-sa`.
   - Open Firefox once so it creates a profile, then switch again to link
     `firefox/` into it.
   - Optional: `bash scripts/ujilink.sh`, `bash scripts/obsautocam.sh`.
     Debloating happens on its own: every switch and every boot run
     `scripts/debloat.sh`.

The hostname must match the `darwinConfigurations` name in `flake.nix`
(`scutil --get LocalHostName`).
