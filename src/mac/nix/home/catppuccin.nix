# Catppuccin mocha, using catppuccin's own theme for each app (catppuccin/nix
# themes every program enabled in home-manager). Neovim is nixvim, which it
# doesn't cover, so its catppuccin colorscheme is set here too.
{ inputs, ... }:

{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    # tmux keeps its pinned catppuccin plugin (programs/tmux.nix)
    tmux.enable = false;
    # Firefox is styled by its own userChrome.css (firefox.nix); catppuccin's
    # theme needs the Firefox Color extension and turns off extension storage
    # in IndexedDB, which would hide every extension's saved settings
    firefox.enable = false;
  };

  programs.nixvim.colorschemes.catppuccin = {
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
      # crust (mocha's darkest) as the background everywhere
      color_overrides.mocha = {
        base = "#11111b";
        mantle = "#11111b";
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
