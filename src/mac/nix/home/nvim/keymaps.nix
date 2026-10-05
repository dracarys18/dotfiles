let
  # silent mapping; `lua` for Lua function actions
  map = mode: key: action: {
    inherit mode key action;
    options.silent = true;
  };
  lua =
    mode: key: fn:
    map mode key { __raw = "function() ${fn} end"; };
  trouble = key: cmd: desc: {
    mode = "n";
    inherit key;
    action = "<cmd>Trouble ${cmd}<cr>";
    options.desc = desc;
  };
in
{
  keymaps = [
    # space is the leader
    (map [ "n" "v" ] "<Space>" "<Nop>")

    # toggles
    (map "n" "<F2>" "<cmd>set number! relativenumber!<cr>")

    # dap
    (lua "n" "<F5>" "require('dap').continue()")
    (lua "n" "<F10>" "require('dap').step_over()")
    (lua "n" "<F11>" "require('dap').step_into()")
    (lua "n" "<F12>" "require('dap').step_out()")
    (lua "n" "<leader>bb" "require('dap').toggle_breakpoint()")
    (lua "n" "<leader>B" "require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))")
    (lua "n" "<leader>lp"
      "require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))"
    )
    (lua "n" "<leader>dr" "require('dap').repl.open()")
    (lua "n" "<leader>dl" "require('dap').run_last()")
    (lua "n" "<leader>dd" "require('dapui').toggle()")

    # navigation
    (map "n" "<leader><leader>" "<c-^>")
    (map "n" "<leader>n" "<cmd>bnext<cr>")
    (map "n" "<leader>p" "<cmd>bprev<cr>")
    (map "n" "<leader>q" "<cmd>bw<cr>")
    (lua "n" "<leader>v" "require('oil').open()")

    # telescope
    (lua "n" "<leader>ff" "require('telescope.builtin').find_files()")
    (lua "n" "<leader>gg" "require('telescope.builtin').live_grep()")
    (lua "n" "<leader>;" "require('telescope.builtin').buffers()")
    (lua "n" "<leader>fh" "require('telescope.builtin').help_tags()")
    (lua "n" "<leader>l"
      "require('telescope.builtin').lsp_references({ include_current_line = true, fname_width = 40 })"
    )
    (lua "n" "<leader>i" "require('telescope.builtin').lsp_incoming_calls({ fname_width = 40 })")
    (map "n" "<C-c>" "<cmd>Telescope commands<cr>")

    # lsp
    (map "n" "K" "<cmd>lua vim.lsp.buf.hover()<cr>")
    (map "n" "<C-k>" "<cmd>lua vim.lsp.buf.definition()<cr>")
    (map "n" "gi" "<cmd>lua vim.lsp.buf.implementation()<cr>")
    (map "n" "gn" "<cmd>lua vim.lsp.buf.rename()<cr>")
    (map "n" "F" "<cmd>lua vim.lsp.buf.format { async = true }<cr>")

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
