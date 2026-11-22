{ pkgs, ... }:

let
  user = "karthihegde";
in
{
  programs.fish.enable = true;
  environment.shells = [ pkgs.fish ];
  users.knownUsers = [ user ];
  users.users.${user} = {
    uid = 501;
    shell = pkgs.fish;
  };
}
