{ inputs, ... }:

{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ./cli.nix
    ./packages.nix
  ];

  home.username = "karthihegde";
  home.homeDirectory = "/home/karthihegde";
  home.stateVersion = "26.05";

  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    imports = [ ./nvim ];
    nixpkgs.source = inputs.nixpkgs;
  };
}
