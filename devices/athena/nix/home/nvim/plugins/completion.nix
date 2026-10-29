{
  plugins.blink-cmp = {
    enable = true;
    settings = {
      keymap = {
        # Tab accepts the selected suggestion (ghost text included) and falls
        # back to snippet jumps / indentation when no menu is open
        preset = "super-tab";
        "<CR>" = [
          "accept"
          "fallback"
        ];
        # finish a ghost-text suggestion without opening the menu
        "<A-y>" = {
          __raw = "require(\"minuet\").make_blink_map()";
        };
      };
      appearance.nerd_font_variant = "mono";
      sources = {
        # "minuet" last: LSP and buffer matches stay ahead of AI suggestions
        default = [
          "lsp"
          "path"
          "buffer"
          "snippets"
          "minuet"
        ];
        providers.minuet = {
          name = "minuet";
          module = "minuet.blink";
          async = true;
          # must cover minuet's request_timeout (5s)
          timeout_ms = 5000;
          score_offset = 50;
        };
      };
      completion = {
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
        };
        # the actual inline suggestions: the selected item is rendered as text
        # in the buffer while typing
        ghost_text.enabled = true;
        # don't fire an AI request on every insert enter
        trigger.prefetch_on_insert = false;
      };
      signature.enabled = true;
    };
  };
}
