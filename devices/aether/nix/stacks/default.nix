# One module per stack from the old ~/Projects, same container names as the
# compose files so service-to-service hostnames keep resolving.
{
  imports = [
    ./authelia.nix
    ./caddy.nix
    ./cartero.nix
    ./cinny.nix
    ./draw.nix
    ./homeassistant.nix
    ./homepage.nix
    ./immich.nix
    ./karakeep.nix
    ./kimai.nix
    ./media.nix
    ./obsidian.nix
    ./opengist.nix
    ./pihole.nix
    ./portainer.nix
    ./searchxng.nix
    ./stirling.nix
    ./tangled.nix
  ];
}
