# Tangled: knot2 from the core repo, built into an image on the box. The
# upstream atcr.io image needs an account, and the core flake's NixOS module
# evaluates the Rust package locally, which this Mac cannot build for linux.
# knot2 listens on 5555 and 22, and the tunnel reaches it by container name,
# so the existing Cloudflare ingress keeps working.
{ config, ... }:

let
  d = "/var/lib/stacks/tangled";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0755 root root -"
    "d ${d}/data/repos 0750 root root -"
    "d ${d}/src 0755 root root -"
  ];

  # rebuild the image with: sudo /etc/tangled-build.sh
  environment.etc."tangled-build.sh".source = ./tangled-build.sh;

  virtualisation.oci-containers.containers = {
    tangled-knot = {
      image = "knot2:latest";
      # KNOT_MASTER_KEY: devices/aether/nix/secrets/tangled-knot.env
      environmentFiles = [ config.sops.secrets."tangled-knot".path ];
      volumes = [
        "${./tangled-config.toml}:/etc/knot/config.toml:ro"
        "${d}/data:/data"
      ];
      # the image's CMD passes the path as a bare argument, which knot-server
      # treats as a subcommand
      cmd = [
        "--config"
        "/etc/knot/config.toml"
      ];
      ports = [
        "127.0.0.1:5555:5555"
        "127.0.0.1:2222:22"
      ];
    };

    tangled-tunnel = {
      image = "cloudflare/cloudflared:latest";
      cmd = [
        "tunnel"
        "run"
      ];
      # TUNNEL_TOKEN: devices/aether/nix/secrets/tangled.env
      environmentFiles = [ config.sops.secrets."tangled".path ];
      dependsOn = [ "tangled-knot" ];
    };
  };
}
