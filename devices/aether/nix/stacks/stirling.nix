# ~/Projects/stirling
{ ... }:

let
  d = "/var/lib/stacks/stirling";
in
{
  systemd.tmpfiles.rules = [ "d ${d} 0755 root root -" "d ${d}/configs 0755 root root -" ];

  virtualisation.oci-containers.containers.stirling-pdf = {
    image = "stirlingtools/stirling-pdf:latest";
    volumes = [ "${d}/configs:/configs" ];
    ports = [ "127.0.0.1:8069:8080" ];
  };
}
