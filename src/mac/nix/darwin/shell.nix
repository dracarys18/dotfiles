{ pkgs, ... }:

let
  user = "karthihegde";
in
{
  # fish from nixpkgs as the login shell, registered in /etc/shells.
  # nix-darwin only sets the shell of users it knows; uid and primary group
  # (gid 20, staff) match the existing account, so nothing else changes.
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  users.knownUsers = [ user ];
  users.users.${user} = {
    uid = 501;
    shell = pkgs.fish;
  };
}
