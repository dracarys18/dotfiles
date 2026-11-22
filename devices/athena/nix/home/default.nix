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

  targets.darwin.copyApps.enable = false;
  targets.darwin.linkApps.enable = true;

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    imports = [
      ./nvim
      inputs.vellum.nixvimModules.default
    ];
    nixpkgs.source = inputs.nixpkgs;
  };

  _module.args.writable =
    path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/${path}";
}
