# User-level config for aether, mirroring the Mac. The parts that are portable
# live here; the Mac's macOS-specific bits (Homebrew paths, the brew/cargo/npm
# guard wrappers, 1Password commit signing, yabai) are deliberately absent.
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

  # the same configuration the Mac uses, imported from its directory rather than
  # copied: one definition of the editor for both machines
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    # copied from devices/athena/nix/home/nvim, not shared: a path input cannot
    # reach outside the flake root, and a common flake is a bigger refactor than
    # this deploy. Keep the two in step until then.
    imports = [ ./nvim ];
    nixpkgs.source = inputs.nixpkgs;
  };
}
