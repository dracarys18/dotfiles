# dotfiles

nix-darwin, NixOS and Home Manager for two machines, one repo.

## Machines

| Host | Role | Hardware | Deploy |
|---|---|---|---|
| athena | macOS laptop | Apple M3 Pro / 18 GB · aarch64-darwin | `make switch` |
| aether | Linux server | x86_64 · NixOS, runs every container stack | `nixos-rebuild switch --flake .#aether` on the box |

## Layout

- `devices/athena/nix` — flake, `darwin/` (system) and `home/` (user) for the Mac
- `devices/aether/nix` — flake, `stacks/` (one module per service) and `secrets/` (sops) for the server
- `config/` — configs for various tools (firefox, vicinae, jellyfin-desktop, obs)

## Fresh machine

### athena (macOS)

```sh
xcode-select --install   # nix needs the Apple SDK; wait for it to finish
git clone https://github.com/dracarys18/dotfiles.git ~/dotfiles && cd ~/dotfiles
make bootstrap-mac
```

### aether (NixOS)

```sh
su -                      # after installing NixOS with the usual ISO
nixos-generate-config --show-hardware-config > /etc/dotfiles/devices/aether/nix/hardware.nix
mkdir -p /var/lib/sops-nix && cp age-keys.txt /var/lib/sops-nix/key.txt
nixos-rebuild switch --flake /etc/dotfiles/devices/aether/nix#aether
```

## Update

```sh
make switch   # apply changes made in the repo to this Mac
make update   # update packages, nvim plugins and treesitter, then switch
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
