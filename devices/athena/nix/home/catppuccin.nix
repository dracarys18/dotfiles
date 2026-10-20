# Catppuccin mocha, using catppuccin's own theme for each app (catppuccin/nix
# themes every program enabled in home-manager). Neovim is nixvim, which it
# doesn't cover, so its catppuccin colorscheme is set here too.
{ inputs, ... }:

let
  theme = import ./themes.nix;
in
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
    # Vesktop is themed by home/vesktop.nix: catppuccin's Discord theme paints
    # real `background` properties on elements, so it beats the --background-*
    # variables that QuickCSS sets and the result is catppuccin, not black
    vesktop.enable = false;
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
      # backgrounds come from home/themes.nix
      color_overrides.mocha = {
        base = theme.bg;
        mantle = theme.bg;
        crust = theme.bg;
        surface0 = theme.bgHighlight;
        surface1 = theme.bgHighlight;
        surface2 = theme.border;
      };
      highlight_overrides.mocha = {
        TabLineSel.bg = theme.accentAlt;
        CmpBorder.fg = "#585b70";
        Pmenu.bg = "NONE";
        TelescopeBorder.link = "FloatBorder";
      };
    };
  };
}
