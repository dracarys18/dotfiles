{
  colorschemes.catppuccin = {
    enable = true;
    settings = {
      flavour = "mocha";
      term_colors = true;
      transparent_background = false;
      no_italic = false;
      no_bold = false;
      styles = {
        comments = [ ];
        conditionals = [ ];
        loops = [ ];
        functions = [ ];
        keywords = [ ];
        strings = [ ];
        variables = [ ];
        numbers = [ ];
        booleans = [ ];
        properties = [ ];
        types = [ ];
      };
      # pure black background
      color_overrides.mocha = {
        base = "#000000";
        mantle = "#000000";
        crust = "#000000";
      };
      # mocha's pink and surface2
      highlight_overrides.mocha = {
        TabLineSel.bg = "#f5c2e7";
        CmpBorder.fg = "#585b70";
        Pmenu.bg = "NONE";
        TelescopeBorder.link = "FloatBorder";
      };
    };
  };
}
