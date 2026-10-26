{
  globals = {
    mapleader = " ";
    maplocalleader = " ";
    python_highlight_all = 1;
  };

  opts = {
    number = true;
    relativenumber = false;
    timeoutlen = 700;
    guifont = "Hasklug Nerd Font Mono,Hack Nerd Font,NotoEmoji Nerd Font:h11";

    # undo history in Neovim's default ~/.local/state/nvim/undo
    undofile = true;

    autoread = true;
    foldmethod = "indent";
    showmode = false;
    showtabline = 0;
    autoindent = true;
    tabstop = 4;
    softtabstop = 4;
    shiftwidth = 4;
    expandtab = true;
    hidden = true;
    wrap = false;
    clipboard = "unnamedplus";
    completeopt = "menuone,noselect,popup";

    ignorecase = true;
    smartcase = true;

    termguicolors = true;
    signcolumn = "yes";
    list = true;
  };

  # reload buffers changed on disk
  autoGroups.AutoRead.clear = true;
  autoCmd = [
    {
      event = [
        "FocusGained"
        "TermClose"
        "TermLeave"
        "BufEnter"
        "CursorHold"
      ];
      group = "AutoRead";
      command = "checktime";
    }
    {
      event = "FileChangedShellPost";
      group = "AutoRead";
      command = "echomsg 'File reloaded from disk'";
    }
  ];
}
