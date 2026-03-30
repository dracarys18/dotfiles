local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- disable space in normal/visual (used as leader)
map({ 'n', 'v' }, '<Space>', '<Nop>', opts)

-- ── Toggles ───────────────────────────────────────────────────────────────────
map('n', '<F2>', '<cmd>set number! relativenumber!<cr>', opts)

-- ── DAP ───────────────────────────────────────────────────────────────────────
map('n', '<F5>',       function() require('dap').continue() end, opts)
map('n', '<F10>',      function() require('dap').step_over() end, opts)
map('n', '<F11>',      function() require('dap').step_into() end, opts)
map('n', '<F12>',      function() require('dap').step_out() end, opts)
map('n', '<leader>bb', function() require('dap').toggle_breakpoint() end, opts)
map('n', '<leader>B',  function() require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, opts)
map('n', '<leader>lp', function() require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: ')) end, opts)
map('n', '<leader>dr', function() require('dap').repl.open() end, opts)
map('n', '<leader>dl', function() require('dap').run_last() end, opts)
map('n', '<leader>dd', function() require('dapui').toggle() end, opts)

-- ── Navigation ────────────────────────────────────────────────────────────────
map('n', '<leader><leader>', '<c-^>', opts)
map('n', '<leader>n',        '<cmd>bnext<cr>', opts)
map('n', '<leader>p',        '<cmd>bprev<cr>', opts)
map('n', '<leader>q',        '<cmd>bw<cr>', opts)
map('n', '<leader>v',        function() require('oil').open() end, opts)

-- ── Telescope ─────────────────────────────────────────────────────────────────
map('n', '<leader>ff', function() require('telescope.builtin').find_files() end, opts)
map('n', '<leader>gg', function() require('telescope.builtin').live_grep() end, opts)
map('n', '<leader>;',  function() require('telescope.builtin').buffers() end, opts)
map('n', '<leader>fh', function() require('telescope.builtin').help_tags() end, opts)
map('n', '<leader>l',  function() require('telescope.builtin').lsp_references({ include_current_line = true, fname_width = 40 }) end, opts)
map('n', '<leader>i',  function() require('telescope.builtin').lsp_incoming_calls({ fname_width = 40 }) end, opts)
map('n', '<C-c>',      '<cmd>Telescope commands<cr>', opts)

-- ── LSP ───────────────────────────────────────────────────────────────────────
map('n', 'K',         '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
map('n', '<C-k>',     '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
map('n', 'gi',        '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
map('n', 'gn',        '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
map('n', 'F',         '<cmd>lua vim.lsp.buf.format { async = true }<cr>', opts)

-- ── Git ───────────────────────────────────────────────────────────────────────
map('n', '<leader>gB', '<cmd>Git blame<cr>', opts)
map('n', 'vff',        '<cmd>vertical Gdiffsplit<cr>', opts)
map('n', 'vff!',       '<cmd>vertical Gdiffsplit!<cr>', opts)

-- ── Rust ──────────────────────────────────────────────────────────────────────
map('n', '<leader>rd', '<cmd>RustDebuggables<cr>', opts)
map('n', '<leader>rr', '<cmd>RustRunnables<cr>', opts)

-- ── Buffers ───────────────────────────────────────────────────────────────────
map('n', 'gt',     ':BufferLineMoveNext<cr>', opts)
map('n', 'gT',     ':BufferLineMovePrev<cr>', opts)
map('n', '<C-W>%', '<cmd>vsplit<cr>', opts)
map('n', '<leader>"', '"+', opts)

-- ── Trouble ───────────────────────────────────────────────────────────────────
map('n', '<leader>o',  '<cmd>Trouble diagnostics toggle<cr>',                          { desc = 'Diagnostics' })
map('n', '<leader>xX', '<cmd>Trouble diagnostics toggle filter.buf=0<cr>',             { desc = 'Buffer Diagnostics' })
map('n', '<leader>cs', '<cmd>Trouble symbols toggle focus=false<cr>',                  { desc = 'Symbols' })
map('n', '<leader>cl', '<cmd>Trouble lsp toggle focus=false win.position=right<cr>',   { desc = 'LSP Definitions' })
map('n', '<leader>xL', '<cmd>Trouble loclist toggle<cr>',                              { desc = 'Location List' })
map('n', '<leader>xQ', '<cmd>Trouble qflist toggle<cr>',                               { desc = 'Quickfix List' })

-- ── Insert ────────────────────────────────────────────────────────────────────
map('i', '<C-j>', '<ESC>', opts)
map('i', '<C-c>', '<cmd>Telescope commands<cr>', opts)

-- ── Other ─────────────────────────────────────────────────────────────────────
map('n', '<leader>m', '<cmd>silent !mpcfzf<cr>', opts)
