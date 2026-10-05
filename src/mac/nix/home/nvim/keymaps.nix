let
  # silent mapping; `lua` only where a plugin has no command for the action
  map = mode: key: action: {
    inherit mode key action;
    options.silent = true;
  };
  lua =
    mode: key: fn:
    map mode key { __raw = "function() ${fn} end"; };
  map2lsp = builtins.map (km: {
    key = builtins.elemAt km 0;
    lspBufAction = builtins.elemAt km 1;
    options.silent = true;
  });
  trouble = key: cmd: desc: {
    mode = "n";
    inherit key;
    action = "<cmd>Trouble ${cmd}<cr>";
    options.desc = desc;
  };
in
{
  # set when a language server attaches to the buffer
  lsp.keymaps = map2lsp [
    [
      "K"
      "hover"
    ]
    [
      "<C-k>"
      "definition"
    ]
    [
      "gi"
      "implementation"
    ]
    [
      "gn"
      "rename"
    ]
    [
      "F"
      "format"
    ]
  ];

  keymaps = [
    # space is the leader
    (map [ "n" "v" ] "<Space>" "<Nop>")

    # toggles
    (map "n" "<F2>" "<cmd>set number! relativenumber!<cr>")

    # dap
    (map "n" "<F5>" "<cmd>DapContinue<cr>")
    (map "n" "<F10>" "<cmd>DapStepOver<cr>")
    (map "n" "<F11>" "<cmd>DapStepInto<cr>")
    (map "n" "<F12>" "<cmd>DapStepOut<cr>")
    (map "n" "<leader>bb" "<cmd>DapToggleBreakpoint<cr>")
    (lua "n" "<leader>B" "require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))")
    (lua "n" "<leader>lp"
      "require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))"
    )
    (map "n" "<leader>dr" "<cmd>DapToggleRepl<cr>")
    (lua "n" "<leader>dl" "require('dap').run_last()")
    (lua "n" "<leader>dd" "require('dapui').toggle()")

    # navigation
    (map "n" "<leader><leader>" "<c-^>")
    (map "n" "<leader>n" "<cmd>bnext<cr>")
    (map "n" "<leader>p" "<cmd>bprev<cr>")
    (map "n" "<leader>q" "<cmd>bw<cr>")
    (map "n" "<leader>v" "<cmd>Oil<cr>")

    # telescope
    (map "n" "<leader>ff" "<cmd>Telescope find_files<cr>")
    (map "n" "<leader>gg" "<cmd>Telescope live_grep<cr>")
    (map "n" "<leader>;" "<cmd>Telescope buffers<cr>")
    (map "n" "<leader>fh" "<cmd>Telescope help_tags<cr>")
    (map "n" "<leader>l" "<cmd>Telescope lsp_references include_current_line=true fname_width=40<cr>")
    (map "n" "<leader>i" "<cmd>Telescope lsp_incoming_calls fname_width=40<cr>")
    (map "n" "<C-c>" "<cmd>Telescope commands<cr>")

    # git
    (map "n" "<leader>gB" "<cmd>Git blame<cr>")
    (map "n" "vff" "<cmd>vertical Gdiffsplit<cr>")
    (map "n" "vff!" "<cmd>vertical Gdiffsplit!<cr>")

    # rust (rustaceanvim)
    (map "n" "<leader>rd" "<cmd>RustLsp debuggables<cr>")
    (map "n" "<leader>rr" "<cmd>RustLsp runnables<cr>")

    # buffers
    (map "n" "gt" ":BufferLineMoveNext<cr>")
    (map "n" "gT" ":BufferLineMovePrev<cr>")
    (map "n" "<C-W>%" "<cmd>vsplit<cr>")
    (map "n" "<leader>\"" "\"+")

    # trouble
    (trouble "<leader>o" "diagnostics toggle" "Diagnostics")
    (trouble "<leader>xX" "diagnostics toggle filter.buf=0" "Buffer Diagnostics")
    (trouble "<leader>cs" "symbols toggle focus=false" "Symbols")
    (trouble "<leader>cl" "lsp toggle focus=false win.position=right" "LSP Definitions")
    (trouble "<leader>xL" "loclist toggle" "Location List")
    (trouble "<leader>xQ" "qflist toggle" "Quickfix List")

    # insert
    (map "i" "<C-j>" "<ESC>")
    (map "i" "<C-c>" "<cmd>Telescope commands<cr>")

    # other
    (map "n" "<leader>m" "<cmd>silent !mpcfzf<cr>")
  ];
}
