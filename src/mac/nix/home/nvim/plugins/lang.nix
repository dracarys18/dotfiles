{ pkgs, ... }:

{
  # rustaceanvim starts rust-analyzer itself (installed by Nix)
  plugins.rustaceanvim.enable = true;

  plugins.zig = {
    enable = true;
    settings = {
      fmt_parse_errors = 0;
      fmt_autosave = 0;
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    go-nvim
    guihua-lua
    d2-vim
  ];
  # go.nvim's textobjects default would overwrite nvim-treesitter's setup
  extraConfigLua = ''
    require('go').setup({
      lsp_goimports = true,
      textobjects = false,
    })
  '';
}
