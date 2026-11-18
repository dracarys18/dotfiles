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
    ./homepage.nix
    ./media.nix
    ./observability.nix
    ./postgres.nix
    ./obsidian.nix
    ./searchxng.nix
    ./shiori.nix
    ./sparkyfitness.nix
    ./bentopdf.nix
    ./tangled.nix
  ];
}
