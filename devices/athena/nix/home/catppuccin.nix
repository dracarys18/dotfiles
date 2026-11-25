{ inputs, ... }:

let
  theme = import ./themes.nix;
in
{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  catppuccin = {
    enable = true;
    flavor = "mocha";
    tmux.enable = false;
    librewolf = {
      enable = true;
      force = true;
    };
    vesktop.enable = false;
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
        LineNr.fg = theme.fgMuted;
        CursorLineNr.fg = theme.accent;
        SignColumn.fg = theme.fgMuted;
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
