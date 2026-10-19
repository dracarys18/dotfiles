# ~/Projects/cinny — image is the user's own build, pushed to Docker Hub
{ ... }:

let
  d = "/var/lib/stacks/cinny";
in
{
  systemd.tmpfiles.rules = [ "d ${d} 0755 root root -" ];

  networking.firewall.allowedTCPPorts = [ 8689 ];

  virtualisation.oci-containers.containers.cinny-app = {
    image = "karthihegde/cinny:latest";
    volumes = [ "${d}/config.json:/usr/share/nginx/html/config.json:ro" ];
    ports = [ "8689:80" ];
  };
}
