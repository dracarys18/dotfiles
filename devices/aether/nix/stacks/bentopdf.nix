{ ... }:

{
  virtualisation.oci-containers.containers.bentopdf = {
    image = "ghcr.io/alam00000/bentopdf-simple:latest";
    extraOptions = [ "--pull=newer" ];
    ports = [ "127.0.0.1:8069:8080" ];
  };
}
