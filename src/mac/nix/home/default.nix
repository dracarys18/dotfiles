# User level (home-manager): one file per concern, imported here.
{ config, inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./programs
    ./packages.nix
    ./files.nix
    ./firefox.nix
    ./obs.nix
  ];

  home.username = "karthihegde";
  home.homeDirectory = "/Users/karthihegde";
  home.stateVersion = "26.05";

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
