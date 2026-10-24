# ~/Projects/draw
{ ... }:

{
  virtualisation.oci-containers.containers.excalidraw = {
    image = "excalidraw/excalidraw:latest";
    ports = [ "127.0.0.1:3035:80" ];
  };
}
