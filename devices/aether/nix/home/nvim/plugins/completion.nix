{
  plugins.blink-cmp = {
    enable = true;
    settings = {
      keymap = {
        preset = "super-tab";
        "<CR>" = [
          "accept"
          "fallback"
        ];
        "<A-y>" = {
          __raw = "require(\"minuet\").make_blink_map()";
        };
      };
      appearance.nerd_font_variant = "mono";
      sources = {
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
          timeout_ms = 5000;
          score_offset = 50;
        };
      };
      completion = {
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 200;
        };
        ghost_text.enabled = true;
        trigger.prefetch_on_insert = false;
      };
      signature.enabled = true;
    };
  };
}
