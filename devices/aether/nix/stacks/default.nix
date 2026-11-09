# One module per stack from the old ~/Projects, same container names as the
# compose files so service-to-service hostnames keep resolving.
{
  imports = [
    ./adguardhome.nix
    ./authelia.nix
    ./caddy.nix
    ./cartero.nix
    ./gatus.nix
    ./homeassistant.nix
    ./media.nix
    ./observability.nix
    ./obsidian.nix
    ./searchxng.nix
    ./shiori.nix
    ./bentopdf.nix
    ./tangled.nix
  ];
}
