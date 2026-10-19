{
  plugins = {
    web-devicons.enable = true;
    which-key.enable = true;
    todo-comments.enable = true;
    colorizer.enable = true;
    fidget.enable = true;

    bufferline = {
      enable = true;
      settings.options.diagnostics = "nvim_lsp";
    };

    lualine = {
      enable = true;
      settings = {
        options = {
          icons_enabled = true;
          theme = "auto";
          component_separators = {
            left = "";
            right = "";
          };
          section_separators = {
            left = "";
            right = "";
          };
          disabled_filetypes = {
            statusline = [ ];
            winbar = [ ];
          };
          ignore_focus = [ ];
          always_divide_middle = true;
          always_show_tabline = true;
          globalstatus = false;
          refresh = {
            statusline = 1000;
            tabline = 1000;
            winbar = 1000;
            refresh_time = 16;
            events = [
              "WinEnter"
              "BufEnter"
              "BufWritePost"
              "SessionLoadPost"
              "FileChangedShellPost"
              "VimResized"
              "Filetype"
              "CursorMoved"
              "CursorMovedI"
              "ModeChanged"
            ];
          };
        };
        sections = {
          lualine_a = [ "mode" ];
          lualine_b = [
            "branch"
            "diff"
            "diagnostics"
          ];
          lualine_c = [ "filename" ];
          lualine_x = [
            "lsp_status"
            "filetype"
          ];
          lualine_y = [ ];
          lualine_z = [ "location" ];
        };
        inactive_sections = {
          lualine_a = [ ];
          lualine_b = [ ];
          lualine_c = [ "filename" ];
          lualine_x = [ "location" ];
          lualine_y = [ ];
          lualine_z = [ ];
        };
      };
    };
  };
}
