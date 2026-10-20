# User level (home-manager): one file per concern, imported here.
{ config, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./programs
    ./packages.nix
    ./catppuccin.nix
    ./vesktop.nix
    ./files.nix
    ./firefox.nix
    ./llama-cpp.nix
    ./obs.nix
    ./autostart.nix
  ];

  home.username = "karthihegde";
  home.homeDirectory = "/Users/karthihegde";
  home.stateVersion = "26.05";

  # Symlink apps into ~/Applications instead of home-manager's default, which
  # copies 1.4 GB of app bundles there on every switch. The copies also made
  # every app exist twice (store + copy), so LaunchServices had two Firefoxes
  # and Firefox treated each path as its own installation.
  targets.darwin.copyApps.enable = false;
  targets.darwin.linkApps.enable = true;

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    imports = [ ./nvim ];
    # build Neovim plugins from the same nixpkgs as everything else
    nixpkgs.source = inputs.nixpkgs;
  };

  # Files an app rewrites itself can't be read-only store copies; link them
  # straight to the repo instead: `writable "config/vicinae/settings.json"`
  _module.args.writable =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
}
