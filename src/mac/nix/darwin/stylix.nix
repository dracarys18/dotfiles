# One theme and font for every app stylix knows how to configure. Stylix
# hands these settings on to home-manager too, so this is the only stylix
# file; app-specific tweaks live in that app's file (home/programs/*.nix).
{ pkgs, ... }:

{
  stylix = {
    enable = true;
    autoEnable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    polarity = "dark";
    fonts = {
      monospace = {
        package = pkgs.nerd-fonts.hasklug;
        name = "Hasklug Nerd Font";
      };
    };
  };
}
