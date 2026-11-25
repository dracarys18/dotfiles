{ lib, ... }:
{
  options.homelab.domain = lib.mkOption {
    type = lib.types.str;
    default = "karthihegde.dev";
  };
}
