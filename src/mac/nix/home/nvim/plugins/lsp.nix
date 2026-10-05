{ pkgs, ... }:

{
  # lspconfig supplies each server's defaults (command, filetypes, root markers)
  plugins.lspconfig.enable = true;
  plugins.lspsaga.enable = true;
  extraPlugins = [ pkgs.vimPlugins.lsp-status-nvim ];

  # servers start through Neovim's own vim.lsp API; Nix installs each one
  lsp.servers = {
    lua_ls = {
      enable = true;
      config = {
        log_level = 2;
        settings.Lua = {
          diagnostics.globals = [ "vim" ];
          telemetry.enable = false;
          formatting.end_of_line = "lf";
        };
      };
    };
    clangd = {
      enable = true;
      config = {
        filetypes = [
          "c"
          "cpp"
          "objc"
          "objcpp"
        ];
        single_file_support = true;
      };
    };
    zls = {
      enable = true;
      config = {
        filetypes = [
          "zig"
          "zon"
        ];
        single_file_support = true;
        settings.zls = {
          enable_inlay_hints = true;
          inlay_hints_hide_redundant_param_names = true;
          enable_ast_check_diagnostics = true;
          warn_style = true;
          semantic_tokens = "partial";
        };
      };
    };
    pylsp.enable = true;
    gopls.enable = true;
    bashls.enable = true;
    ts_ls.enable = true;
    terraformls.enable = true;
    # from your opam switch, so it matches the OCaml compiler in use
    ocamllsp = {
      enable = true;
      package = null;
    };
  };

  # every server: lsp-status's progress handlers and blink's completion
  # capabilities (rust-analyzer is started by rustaceanvim, see lang.nix)
  extraConfigLua = ''
    local lspstatus = require('lsp-status')
    local base_caps = vim.tbl_deep_extend('force',
      vim.lsp.protocol.make_client_capabilities(),
      lspstatus.capabilities
    )
    local ok, blink = pcall(require, 'blink.cmp')
    vim.lsp.config('*', {
      capabilities = ok and blink.get_lsp_capabilities(base_caps) or base_caps,
      on_attach = lspstatus.on_attach,
    })
  '';
}
