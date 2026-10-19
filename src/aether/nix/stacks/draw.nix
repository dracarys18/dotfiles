# ~/Projects/draw
{ ... }:

{
  networking.firewall.allowedTCPPorts = [ 3035 ];

  virtualisation.oci-containers.containers.excalidraw = {
    image = "excalidraw/excalidraw:latest";
    ports = [ "3035:80" ];
  };
}
