# One module per stack from the old ~/Projects, same container names as the
# compose files so service-to-service hostnames keep resolving.
{
  imports = [
    ./adguardhome.nix
    ./authelia.nix
    ./caddy.nix
    ./cartero.nix
    ./homeassistant.nix
    ./homepage.nix
    ./karakeep.nix
    ./media.nix
    ./obsidian.nix
    ./searchxng.nix
    ./stirling.nix
    # tangled: knot is built from a source checkout that is not in this repo
  ];
}
