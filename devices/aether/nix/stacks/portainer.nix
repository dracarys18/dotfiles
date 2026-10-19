# ~/Projects/portainer — manages podman through its docker-compatible socket
let
  d = "/var/lib/stacks/portainer";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/data 0755 root root -"
  ];

  networking.firewall.allowedTCPPorts = [
    8000 # edge agent tunnel
    9000 # http
    9443 # https
  ];

  virtualisation.oci-containers.containers.portainer = {
    image = "ngxson/portainer-ce-without-annoying:latest";
    volumes = [
      "/run/podman/podman.sock:/var/run/docker.sock"
      "${d}/data:/data"
    ];
    ports = [
      "8000:8000"
      "9000:9000"
      "9443:9443"
    ];
    cmd = [ "--http-enabled" ];
  };
}
