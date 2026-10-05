{ pkgs, ... }:

{
  plugins = {
    oil.enable = true;
    trouble.enable = true;
    diffview.enable = true;

    gitsigns = {
      enable = true;
      settings.current_line_blame = true;
    };

    toggleterm = {
      enable = true;
      settings = {
        size = 70;
        # a Lua expression in nixvim, hence the [[ ]] string quotes
        open_mapping = "[[<c-\\>]]";
        hide_numbers = true;
        shade_terminals = true;
        shading_factor = "1";
        start_in_insert = true;
        persist_size = true;
        direction = "float";
        close_on_exit = true;
        shell.__raw = "vim.o.shell";
        float_opts = {
          border = "single";
          width = 200;
          height = 50;
          winblend = 3;
          highlights = {
            border = "Normal";
            background = "Normal";
          };
        };
      };
    };

    # tpope
    commentary.enable = true;
    repeat.enable = true;
    vim-surround.enable = true;
    fugitive.enable = true;
    abolish.enable = true;
  };

  extraPlugins = with pkgs.vimPlugins; [
    vim-speeddating
    vim-mergetool
  ];
}
