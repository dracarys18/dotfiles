{
  programs.zoxide = {
    enable = true;
    # `cd` jumps by frecency, like the old `alias cd=z`
    options = [ "--cmd cd" ];
  };
}
