{ config, ... }:

{
  services.caddy.virtualHosts."pdf.${config.homelab.domain}".extraConfig = "import gated 8069";

  virtualisation.oci-containers.containers.bentopdf = {
    image = "ghcr.io/alam00000/bentopdf-simple@sha256:ebea1678d2cdd500af57987f802d442931b46a73b12af788d1831f6204b8a477";
    ports = [ "127.0.0.1:8069:8080" ];
  };
}
