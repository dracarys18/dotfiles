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
  ];
}
