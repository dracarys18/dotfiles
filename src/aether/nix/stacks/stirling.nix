# ~/Projects/stirling
{ ... }:

let
  d = "/var/lib/stacks/stirling";
in
{
  systemd.tmpfiles.rules = [ "d ${d} 0755 root root -" "d ${d}/configs 0755 root root -" ];

  networking.firewall.allowedTCPPorts = [ 8069 ];

  virtualisation.oci-containers.containers.stirling-pdf = {
    image = "stirlingtools/stirling-pdf:latest";
    volumes = [ "${d}/configs:/configs" ];
    ports = [ "8069:8080" ];
  };
}
