vim.g.mapleader      = ' '
vim.g.maplocalleader = ' '

-- line numbers
vim.o.number         = true
vim.o.relativenumber = false

-- timing
vim.o.timeoutlen     = 700

-- gui
vim.o.guifont        = 'Hasklug Nerd Font Mono,Hack Nerd Font,NotoEmoji Nerd Font:h11'

-- undo
vim.o.undodir        = vim.fn.stdpath('cache') .. '/undodir'
vim.o.undofile       = true

-- editing
vim.o.autoread       = true
vim.o.foldmethod     = 'indent'
vim.o.showmode       = false
vim.o.showtabline    = 0
vim.o.autoindent     = true
vim.o.tabstop        = 4
vim.o.softtabstop    = 4
vim.o.shiftwidth     = 4
vim.o.expandtab      = true
vim.o.hidden         = true
vim.o.wrap           = false
vim.o.clipboard      = 'unnamedplus'
vim.o.completeopt    = 'menuone,noselect,popup'

-- search
vim.o.ignorecase     = true
vim.o.smartcase      = true

-- ui
vim.o.termguicolors  = true
vim.wo.signcolumn    = 'yes'
vim.opt.list         = true

-- zig
vim.g.zig_fmt_parse_errors = 0
vim.g.zig_fmt_autosave     = 0

-- python
vim.g.python_highlight_all = 1
