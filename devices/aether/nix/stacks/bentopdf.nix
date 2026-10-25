# ~/Projects/stirling, replaced by BentoPDF: the client-side equivalent. Same
# hostname and host port as the Stirling container it replaces, so caddy.nix
# needs no change. Nothing to persist — the image is static files and every
# operation runs in the browser, so this is ~20 MB of RSS instead of ~700 MB
# of Java, and documents never leave the machine they were opened on.
{ ... }:

{
  virtualisation.oci-containers.containers.bentopdf = {
    image = "ghcr.io/alam00000/bentopdf-simple:latest";
    ports = [ "127.0.0.1:8069:8080" ];
  };
}
