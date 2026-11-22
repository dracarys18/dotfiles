{ pkgs, ... }:

{
  xdg.configFile."1Password/ssh/agent.toml".source = (pkgs.formats.toml { }).generate "agent.toml" {
    ssh-keys = [ { vault = "Personal"; } ];
  };
}
