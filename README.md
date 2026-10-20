# dotfiles

nix-darwin, NixOS and Home Manager for two machines, one repo.

## Machines

| Host | Role | Hardware | Deploy |
|---|---|---|---|
| athena | macOS laptop | Apple M3 Pro / 18 GB · aarch64-darwin | `make switch` |
| aether | Linux server | x86_64 · NixOS, runs every container stack | `make switch HOST=aether` |

## Layout

- `devices/athena/nix` — flake, `darwin/` (system) and `home/` (user) for the Mac
- `devices/aether/nix` — flake, `stacks/` (one module per service) and `secrets/` (sops) for the server
- `config/` — configs for various tools (firefox, vicinae, jellyfin-desktop, obs)

## Fresh machine

### athena (macOS)

```sh
xcode-select --install   # nix needs the Apple SDK; wait for it to finish
git clone https://github.com/dracarys18/dotfiles.git ~/dotfiles && cd ~/dotfiles
make bootstrap
```

### aether (NixOS)

Install NixOS with the usual ISO, then from athena — `make bootstrap HOST=aether`
reads the disk layout back into `devices/aether/nix/hardware.nix`, copies this
repo to `/etc/dotfiles`, installs the sops age key and makes the first switch.
It expects `aether` in `~/.ssh/config`.

## Update

```sh
make switch                    # apply changes to this Mac
make switch HOST=aether        # rsync the repo, then nixos-rebuild on the box
make update                    # update the Mac's flake.lock (packages, nvim
                               # plugins, parsers), then switch
make update HOST=aether        # same for the server's lock
make check                     # evaluate both configs, build nothing
```

`make` lists the rest.

## Secrets

Everything encrypted with sops (`.sops.yaml` at the root). The age key lives at
`~/Library/Application Support/sops/age/keys.txt` on athena and at
`/var/lib/sops-nix/key.txt` on aether; edit with `sops devices/aether/nix/secrets/<stack>.env`.

## Validating

```sh
darwin-rebuild build --flake devices/athena/nix#mac     # build the Mac config
nixos-rebuild build --flake devices/aether/nix#aether   # build the server config
```
