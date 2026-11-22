{ pkgs, ... }:

{
  plugins.rustaceanvim.enable = true;

  plugins.zig = {
    enable = true;
    settings = {
      fmt_parse_errors = 0;
      fmt_autosave = 1;
    };
  };

  extraPlugins = with pkgs.vimPlugins; [
    go-nvim
    guihua-lua
    d2-vim
  ];
  extraConfigLua = ''
    require('go').setup({
      lsp_goimports = true,
      textobjects = false,
    })

    -- go.nvim `go install`s any tool it finds missing, outside Nix; make it
    -- say so instead (Go tools come from home.packages in the dotfiles)
    local function refuse(bin)
      if bin and vim.fn.executable(bin) == 1 then return true end
      vim.notify((bin or 'Go tools') .. ' not installed: add it to home.packages in ~/dotfiles', vim.log.levels.WARN)
      return false
    end
    local installer = require('go.install')
    for _, name in ipairs({ 'install', 'update', 'update_sync', 'install_all', 'install_all_sync', 'update_all', 'update_all_sync' }) do
      installer[name] = refuse
    end
  '';
}
