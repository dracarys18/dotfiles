{
  programs.uji = {
    enable = true;
    # this policy and these keys replace uji's own
    defaults = false;

    toolPolicy = {
      default = "allow";
      run_command.deny = [ ''/^\s*rm\s+-rf/'' ];
      Bash.deny = [ ''/^\s*rm\s+-rf/'' ];
    };

    keymaps.normal."<C-e>".command = "effort";

    # the checkout from `make uji` instead of the flake's copy, so plugin
    # edits apply without a switch
    packs.uji-plugins.dir = "~/Projects/uji-plugins";

    plugins = {
      statusline.enable = true;
      planmode.enable = true;
      telescope = {
        enable = true;
        settings.editor = "nvim";
      };
      websearch.enable = true;
      mcp.enable = true;
      skills = {
        enable = true;
        settings.roots = [ "~/Projects/uji-skills" ];
      };
      themes.enable = true;
      claude_code.enable = true;
    };
  };
}
