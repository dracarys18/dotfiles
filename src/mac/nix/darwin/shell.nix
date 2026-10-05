{ pkgs, ... }:

let
  user = "karthihegde";
in
{
  # fish from nixpkgs, registered in /etc/shells; the login shell is set below
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];

  # Activation runs as root, so dscl sets the shell without a password (unlike chsh)
  system.activationScripts.postActivation.text = ''
    echo "setting login shell to nix fish..."
    dscl . -create /Users/${user} UserShell /run/current-system/sw/bin/fish
  '';
}
