{ pkgs, ... }:

{
  # 1Password's SSH agent offers the keys in the Personal vault
  xdg.configFile."1Password/ssh/agent.toml".source = (pkgs.formats.toml { }).generate "agent.toml" {
    ssh-keys = [ { vault = "Personal"; } ];
  };
}
