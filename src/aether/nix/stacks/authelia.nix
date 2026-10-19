# ~/Projects/authelia — only reachable from localhost, the reverse proxy is
# what fronts it
{ ... }:

let
  d = "/var/lib/stacks/authelia";
in
{
  systemd.tmpfiles.rules = [
    "d ${d} 0755 root root -"
    "d ${d}/config 0755 root root -"
  ];

  virtualisation.oci-containers.containers.authelia = {
    image = "ghcr.io/authelia/authelia:latest";
    environment.TZ = "Asia/Kolkata";
    volumes = [ "${d}/config:/config" ];
    ports = [ "127.0.0.1:9091:9091" ];
  };
}
