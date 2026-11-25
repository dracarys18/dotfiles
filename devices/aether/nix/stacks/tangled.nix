{ config, ... }:

let
  d = "/var/lib/stacks/tangled";
in
{
  services.caddy.virtualHosts."tangled.${config.homelab.domain}".extraConfig = "import proxy 5555";

  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0755 root root -"
    "d ${d}/data/repos 0750 root root -"
    "d ${d}/src 0755 root root -"
  ];

  environment.etc."tangled-build.sh".source = ./tangled-build.sh;

  virtualisation.oci-containers.containers = {
    tangled-knot = {
      image = "knot2:latest";
      environmentFiles = [ config.sops.secrets."tangled-knot".path ];
      volumes = [
        "${./tangled-config.toml}:/etc/knot/config.toml:ro"
        "${d}/data:/data"
      ];
      cmd = [
        "--config"
        "/etc/knot/config.toml"
      ];
      ports = [
        "127.0.0.1:5555:5555"
        "127.0.0.1:2222:22"
      ];
    };
  };
}
