{
  config,
  lib,
  ...
}:

let
  cfg = config.plugins.vellum;
in
{
  options.plugins.vellum = {
    enable = lib.mkEnableOption "vellum.nvim markdown preview";

    settings = lib.mkOption {
      type = lib.types.submodule { freeformType = lib.types.attrs; };
      default = { };
      description = "Options passed to `require('vellum').setup`.";
    };
  };

  config = lib.mkIf cfg.enable {
    extraConfigLua = "require('vellum').setup(${lib.generators.toLua { } cfg.settings})";
  };
}
