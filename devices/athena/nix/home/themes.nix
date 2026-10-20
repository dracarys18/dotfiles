# One palette for everything that gets themed from this repo: pure black
# surfaces with catppuccin mocha foregrounds and accents, so the apps match the
# tmux status line. Not a module and not a wrapper — each app still needs its
# own adapter (catppuccin colour overrides for Neovim, CSS variables for
# Vesktop), this file just decides the colours once.
#
# Ghostty is deliberately excluded: programs/ghostty.nix owns the terminal's
# palette.
rec {
  # surfaces
  bg = "#000000"; # main background
  bgAlt = "#0a0a0a"; # floating windows, raised panels
  bgHighlight = "#111111"; # cursorline, hover, selected
  border = "#1e1e2e"; # splits, float borders

  # text
  fg = "#cdd6f4"; # primary text
  fgMuted = "#6c7086"; # comments, secondary text

  # accents
  accent = "#cba6f7"; # mauve — matches tmux and lualine
  accentAlt = "#f5c2e7"; # pink — matches the TabLineSel highlight
}
