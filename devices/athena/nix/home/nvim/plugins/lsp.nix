{
  plugins.lspconfig.enable = true;
  plugins.lspsaga.enable = true;

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
    ocamllsp = {
      enable = true;
      package = null;
    };
  };

}
