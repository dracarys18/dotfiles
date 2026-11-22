{ inputs, ... }:

{
  imports = [ inputs.sops-nix.darwinModules.default ];

  sops = {
    age.keyFile = "/Users/karthihegde/Library/Application Support/sops/age/keys.txt";
    defaultSopsFile = ../secrets/secrets.yaml;

    secrets = {
      "litellm/api_key" = {
        owner = "karthihegde";
        mode = "0400";
      };
      "litellm/base_url" = {
        owner = "karthihegde";
        mode = "0400";
      };
      "deepseek/api_key" = {
        owner = "karthihegde";
        mode = "0400";
      };
    };
  };
}
