{
  programs.uji = {
    enable = true;
    defaults = false;

    toolPolicy = {
      default = "allow";
      run_command.deny = [ ''/^\s*rm\s+-rf/'' ];
      Bash.deny = [ ''/^\s*rm\s+-rf/'' ];
    };

    keymaps.normal."<C-e>".command = "effort";

    packs.uji-plugins.dir = "~/Projects/uji-plugins";

    plugins = {
      statusline.enable = false;
      planmode.enable = true;
      telescope = {
        enable = true;
        settings.editor = "nvim";
      };
      websearch = {
        enable = true;
        settings = {
          backend = "searxng";
          url = "https://search.karthihegde.dev";
        };
      };
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
