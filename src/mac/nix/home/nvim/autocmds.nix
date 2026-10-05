{
  autoCmd = [
    # persist folds/views across sessions
    {
      event = [
        "BufWinLeave"
        "BufLeave"
        "BufWritePost"
        "BufHidden"
        "QuitPre"
      ];
      pattern = "?*";
      nested = true;
      command = "silent! mkview!";
    }
    {
      event = "BufWinEnter";
      pattern = "?*";
      command = "silent! loadview";
    }
    {
      event = [
        "BufNewFile"
        "BufRead"
      ];
      pattern = "*.sol";
      command = "set ft=solidity";
    }
    # zig: format on save through the LSP
    {
      event = "BufWritePre";
      pattern = [
        "*.zig"
        "*.zon"
      ];
      callback.__raw = "function() vim.lsp.buf.format() end";
    }
  ];
}
