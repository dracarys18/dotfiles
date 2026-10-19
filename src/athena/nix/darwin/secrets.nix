# Secrets: `secrets/secrets.yaml` is SOPS-encrypted; sops-nix decrypts it at
# activation and at boot into /run/secrets, readable only by the owners listed
# here. The age private key lives outside the store at
# ~/Library/Application Support/sops/age/keys.txt (where sops looks on macOS) —
# without it nothing can be decrypted.
#
#   sops src/athena/nix/secrets/secrets.yaml     # edit (set EDITOR if it complains)
#
# Add a secret: put it in that file, list it here with an owner, then use
# /run/secrets/<name> (owner and mode are per secret).
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
    };
  };
}
