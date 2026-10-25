# ~/Projects/tangled — `knot` is not a registry image, it is built from
# knot-docker/Dockerfile, so a oneshot service builds it before the container
# starts. Put the source at /var/lib/stacks/tangled/knot-docker.
{ config, ... }:

let
  d = "/var/lib/stacks/tangled";
  podman = "${config.virtualisation.podman.package}/bin/podman";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/knot-docker 0755 root root -"
    "d ${d}/knot-data 0755 root root -"
    "d ${d}/knot-repos 0755 root root -"
    "d ${d}/knot-repos/database 0755 root root -"
  ];

  systemd.services.podman-build-knot = {
    description = "build the knot image from /var/lib/stacks/tangled/knot-docker";
    # not wantedBy: the Dockerfile has to be put there by hand, so this would
    # otherwise fail on every boot and mark the system degraded — which makes
    # deploy-rs roll the activation back
    before = [ "podman-tangled-knot.service" ];
    requiredBy = [ "podman-tangled-knot.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      test -f ${d}/knot-docker/Dockerfile ||
        { echo "missing ${d}/knot-docker/Dockerfile" >&2; exit 1; }
      ${podman} build -t knot:latest ${d}/knot-docker
    '';
  };

  virtualisation.oci-containers.containers = {
    tangled-knot = {
      image = "knot:latest";
      # dormant: the image has to be built from a source checkout that isn't in
      # the repo, so starting it on a fresh box only produces a failed unit
      autoStart = false;
      environment = {
        KNOT_SERVER_HOSTNAME = "tangled.karthihegde.dev";
        KNOT_SERVER_OWNER = "did:plc:qhjzsqj3vfzpolc7ayswl7rv";
        KNOT_REPO_SCAN_PATH = "/home/git/repositories";
        KNOT_SERVER_INTERNAL_LISTEN_ADDR = "127.0.0.1:5444";
        KNOT_SERVER_DB_PATH = "/home/git/database/knotserver.db";
      };
      # KNOT_SERVER_SECRET is a secret: devices/aether/nix/secrets/tangled.env
      environmentFiles = [ config.sops.secrets."tangled".path ];
      volumes = [
        "${d}/knot-data:/knot"
        "${d}/knot-repos:/home/git/repositories"
        "${d}/knot-repos/database:/home/git/database"
      ];
    };

    tangled-tunnel = {
      image = "cloudflare/cloudflared:latest";
      cmd = [ "tunnel" "run" ];
      # nothing to tunnel to while knot is dormant
      autoStart = false;
      # TUNNEL_TOKEN is a secret: devices/aether/nix/secrets/tangled.env
      environmentFiles = [ config.sops.secrets."tangled".path ];
    };
  };
}
