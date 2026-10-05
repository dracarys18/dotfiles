{
  stylix = {
    # stylix would otherwise theme every app it knows, writing GTK, Xresources,
    # gedit… files that only Linux apps read. Pick the targets explicitly.
    # (tmux, fish and Neovim keep catppuccin's own hand-made themes.)
    autoEnable = false;
    targets = {
      ghostty.enable = true;
      bat.enable = true;
      fzf.enable = true;
    };
  };
}
