{
  programs.starship = {
    enable = true;
    settings = {
      username.format = "[karthihegde]($style) in ";
      aws = {
        format = "on [(\\($region\\) )]($style)";
        style = "bold blue";
        symbol = "🅰 ";
      };
    };
  };
}
