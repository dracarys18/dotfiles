# dotfiles

One Mac, described by Nix: nix-darwin handles the system (Nix, login shell,
fonts, Homebrew apps, macOS settings), home-manager handles the user (CLI tools
and the files in `config/`).

| Path                      | What it holds                                                 |
| ------------------------- | ------------------------------------------------------------- |
| `src/mac/nix/flake.nix`   | Inputs (nixpkgs 26.05, nix-darwin, home-manager) and the host |
| `src/mac/nix/darwin.nix`  | System settings, Homebrew casks/taps, debloat                 |
| `src/mac/nix/home.nix`    | CLI packages and which file in `config/` goes where           |
| `src/mac/config/`         | Mac-only configs (yabai, skhd, OBS settings snapshot)         |
| `src/mac/scripts/`        | `debloat.sh`, `obsautocam.sh` (both run by Nix), `obs-save.sh` |
| `src/mac/obs/`            | Source of the OBS camera watcher                              |
| `config/`                 | Config files shared by every machine                          |
| `scripts/`                | `ujilink.sh`, run by hand                                     |

Machine-specific setup lives under `src/<platform>/`; a Linux machine gets `src/linux/`.

## Day to day

```sh
sudo darwin-rebuild switch --flake ~/dotfiles/src/mac/nix   # apply changes
nix flake update --flake ~/dotfiles/src/mac/nix   # bump nixpkgs and friends, then switch
sudo darwin-rebuild --rollback                            # undo the last switch
```

- Add a CLI tool: put it in `home.packages` in `src/mac/nix/home.nix`, then switch.
- Add a GUI app: put it in `homebrew.casks` in `src/mac/nix/darwin.nix`, then switch.
  Anything installed with `brew install` and not listed there is removed on the
  next switch.
- Config files are read-only copies in the Nix store. Edit them in
  `~/dotfiles/config`, then switch. `nvim-pack-lock.json` and vicinae's
  `settings.json` are linked straight to the repo, because the apps rewrite them.
- New files must be `git add`ed before switching: flakes only see tracked files.
- OBS rewrites its own settings, so Nix only seeds them on a fresh Mac. After
  changing OBS settings you want to keep, run `src/mac/scripts/obs-save.sh`
  (stream keys and logins are blanked) and commit. Re-enter keys on a new Mac.

## Fresh Mac

1. Install Nix: `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install)`
2. Install Homebrew from https://brew.sh (nix-darwin manages its packages, not
   Homebrew itself).
3. Clone: `git clone https://github.com/dracarys18/dotfiles.git ~/dotfiles`
4. First switch, before `darwin-rebuild` exists:
   ```sh
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run nix-darwin/nix-darwin-26.05#darwin-rebuild -- switch --flake ~/dotfiles/src/mac/nix
   ```
   If it stops on files in `/etc` it doesn't recognise, rename them as it says
   (e.g. `sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin`) and run it again.
5. By hand:
   - yabai scripting addition needs SIP partly off: Recovery Mode → Terminal →
     `csrutil enable --without debug --without fs`, reboot, `sudo yabai --load-sa`.
   - Open Firefox once so it creates a profile, then switch again to link
     `firefox/` into it.
   - Optional: `bash scripts/ujilink.sh`. Debloat and the OBS camera watcher
     are set up by the switch.

The hostname must match the `darwinConfigurations` name in `src/mac/nix/flake.nix`
(`scutil --get LocalHostName`).
