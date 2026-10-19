# ~/Projects/opengist
{ config, ... }:

let
  d = "/var/lib/stacks/opengist";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [ 2222 ];

  virtualisation.oci-containers.containers = {
    opengist = {
      image = "ghcr.io/thomiceli/opengist:latest";
      environment.OG_EXTERNAL_URL = "https://gist.karthihegde.dev";
      volumes = [ "${d}/data:/opengist/data" ];
      ports = [ "2222:2222" ];
    };

    cloudflared-tunnel = {
      image = "cloudflare/cloudflared:latest";
      cmd = [
        "tunnel"
        "--no-autoupdate"
        "run"
      ];
      # TUNNEL_TOKEN is a secret: src/aether/nix/secrets/opengist.env
      environmentFiles = [ config.sops.secrets."opengist".path ];
    };
  };
}
