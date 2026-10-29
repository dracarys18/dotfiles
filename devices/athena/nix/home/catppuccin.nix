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
    # Ghostty is a cask now, so this module has nothing to write into: the
    # theme is picked by name in programs/ghostty.nix instead
    ghostty.enable = false;
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
        # catppuccin paints line numbers and the sign column with surface1,
        # which the overrides above turn into #111111, so both vanish against
        # the black background
        LineNr.fg = theme.fgMuted;
        CursorLineNr.fg = theme.accent;
        SignColumn.fg = theme.fgMuted;
        # spell the diagnostics out instead of relying on catppuccin's
        # defaults, so an update cannot silently drop them again
        DiagnosticError = {
          fg = "#f38ba8";
          bg = "NONE";
        };
        DiagnosticWarn = {
          fg = "#f9e2af";
          bg = "NONE";
        };
        DiagnosticInfo = {
          fg = "#89b4fa";
          bg = "NONE";
        };
        DiagnosticHint = {
          fg = "#94e2d5";
          bg = "NONE";
        };
        DiagnosticSignError = {
          fg = "#f38ba8";
          bg = "NONE";
        };
        DiagnosticSignWarn = {
          fg = "#f9e2af";
          bg = "NONE";
        };
        DiagnosticSignInfo = {
          fg = "#89b4fa";
          bg = "NONE";
        };
        DiagnosticSignHint = {
          fg = "#94e2d5";
          bg = "NONE";
        };
        DiagnosticVirtualTextError = {
          fg = "#f38ba8";
          bg = "NONE";
        };
        DiagnosticVirtualTextWarn = {
          fg = "#f9e2af";
          bg = "NONE";
        };
        DiagnosticVirtualTextInfo = {
          fg = "#89b4fa";
          bg = "NONE";
        };
        DiagnosticVirtualTextHint = {
          fg = "#94e2d5";
          bg = "NONE";
        };
        # underline as well as undercurl: terminals that cannot draw a curly
        # underline still show a straight one
        DiagnosticUnderlineError = {
          undercurl = true;
          underline = true;
          sp = "#f38ba8";
        };
        DiagnosticUnderlineWarn = {
          undercurl = true;
          underline = true;
          sp = "#f9e2af";
        };
        DiagnosticUnderlineInfo = {
          undercurl = true;
          underline = true;
          sp = "#89b4fa";
        };
        DiagnosticUnderlineHint = {
          undercurl = true;
          underline = true;
          sp = "#94e2d5";
        };
      };
    };
  };
}
