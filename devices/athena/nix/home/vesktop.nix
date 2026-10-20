# Vesktop is Vencord's Discord client, so its theme is a CSS file: QuickCSS.
# Vencord injects QuickCSS after the theme plugins, so these variables win over
# the catppuccin Discord theme without disabling it. Both the current Discord
# variables (--bg-*) and the legacy ones (--background-*) are set, because the
# bundled client still uses a mix of the two.
#
# The file is a store copy, not `writable`: home/themes.nix is the source of
# truth, so edits go there and land after `make switch`, not in the in-app CSS
# editor.
{ ... }:

let
  theme = import ./themes.nix;
in
{
  home.file."Library/Application Support/vesktop/settings/quickCss.css".text = ''
    :root,
    .theme-dark,
    .theme-darker,
    .theme-midnight,
    html,
    body {
      /* surfaces */
      --background-primary: ${theme.bg};
      --background-secondary: ${theme.bg};
      --background-secondary-alt: ${theme.bg};
      --background-tertiary: ${theme.bg};
      --background-accent: ${theme.bgHighlight};
      --background-floating: ${theme.bgAlt};
      --background-mobile-primary: ${theme.bg};
      --background-mobile-secondary: ${theme.bg};

      --bg-base-primary: ${theme.bg};
      --bg-base-secondary: ${theme.bg};
      --bg-base-tertiary: ${theme.bg};
      --bg-surface-raised: ${theme.bgAlt};
      --bg-surface-overlay: ${theme.bgAlt};
      --bg-surface-higher: ${theme.bgAlt};
      --bg-surface-lower: ${theme.bg};

      /* interaction states */
      --background-mentioned: rgba(255, 255, 255, 0.04);
      --background-mentioned-hover: rgba(255, 255, 255, 0.06);
      --background-message-hover: rgba(255, 255, 255, 0.03);
      --background-modifier-hover: rgba(255, 255, 255, 0.04);
      --background-modifier-accent: rgba(255, 255, 255, 0.06);
      --background-modifier-selected: rgba(255, 255, 255, 0.08);

      /* text */
      --text-normal: ${theme.fg};
      --text-muted: ${theme.fgMuted};
      --text-link: ${theme.accent};

      /* keep the catppuccin accent instead of blurple */
      --brand-experiment: ${theme.accent};
      --brand-experiment-560: ${theme.accent};
      --brand-experiment-600: ${theme.accent};
      --interactive-active: ${theme.fg};
      --interactive-muted: ${theme.fgMuted};

      /* dividers/borders */
      --border-subtle: ${theme.border};
      --border-strong: ${theme.border};
    }
  '';
}
