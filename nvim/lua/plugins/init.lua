-- Plugin list — managed by vim.pack (Neovim 0.12+)
--
-- To add a build step for a plugin, add these fields to its spec:
--   build  : shell cmd list, vim command string (":TSUpdate"), or lua function
--   check  : path relative to plugin dir — build is skipped if this exists
--
-- Update : vim.pack.update()
-- Lock   : nvim-pack-lock.json (commit this)

local plugins = {
    -- core deps
    { src = 'ssh://git@ssh.github.com:443/nvim-lua/plenary.nvim' },
    { src = 'ssh://git@ssh.github.com:443/nvim-tree/nvim-web-devicons' },

    -- ui
    { src = 'ssh://git@ssh.github.com:443/catppuccin/nvim',              name = 'catppuccin' },
    { src = 'ssh://git@ssh.github.com:443/nvim-lualine/lualine.nvim' },
    { src = 'ssh://git@ssh.github.com:443/akinsho/bufferline.nvim' },
    { src = 'ssh://git@ssh.github.com:443/j-hui/fidget.nvim' },
    { src = 'ssh://git@ssh.github.com:443/folke/which-key.nvim' },
    { src = 'ssh://git@ssh.github.com:443/folke/todo-comments.nvim' },
    { src = 'ssh://git@ssh.github.com:443/norcalli/nvim-colorizer.lua' },

    -- editor
    { src = 'ssh://git@ssh.github.com:443/stevearc/oil.nvim' },
    { src = 'ssh://git@ssh.github.com:443/akinsho/toggleterm.nvim' },
    { src = 'ssh://git@ssh.github.com:443/lewis6991/gitsigns.nvim' },
    { src = 'ssh://git@ssh.github.com:443/sindrets/diffview.nvim' },
    { src = 'ssh://git@ssh.github.com:443/folke/trouble.nvim' },
    { src = 'ssh://git@ssh.github.com:443/samoshkin/vim-mergetool' },

    -- tpope
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-commentary' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-repeat' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-speeddating' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-surround' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-abolish' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-fugitive' },

    -- telescope
    { src = 'ssh://git@ssh.github.com:443/nvim-telescope/telescope.nvim' },
    {
        src = 'ssh://git@ssh.github.com:443/nvim-telescope/telescope-fzf-native.nvim',
        build = { 'make' },
        check = 'build'
    },
    { src = 'ssh://git@ssh.github.com:443/nvim-telescope/telescope-ui-select.nvim' },

    -- lsp
    { src = 'ssh://git@ssh.github.com:443/neovim/nvim-lspconfig' },
    { src = 'ssh://git@ssh.github.com:443/nvim-lua/lsp-status.nvim' },
    { src = 'ssh://git@ssh.github.com:443/williamboman/mason.nvim',                version = vim.version.range('^1.0.0') },
    { src = 'ssh://git@ssh.github.com:443/williamboman/mason-lspconfig.nvim',      version = vim.version.range('^1.0.0') },
    { src = 'ssh://git@ssh.github.com:443/glepnir/lspsaga.nvim' },

    -- completion
    { src = 'git@github.com:fang2hou/blink-copilot.git' },
    {
        src = 'ssh://git@ssh.github.com/saghen/blink.cmp',
        version = vim.version.range('1.*'),
        build = { 'cargo', 'build', '--release', '--locked' },
        check = 'target/release'
    },

    -- copilot
    { src = 'ssh://git@ssh.github.com:443/zbirenbaum/copilot.lua' },

    -- treesitter
    {
        src = 'ssh://git@ssh.github.com:443/nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        check = 'parser'
    },
    { src = 'ssh://git@ssh.github.com:443/nvim-treesitter/nvim-treesitter-context' },

    -- language support
    { src = 'ssh://git@ssh.github.com:443/mrcjkb/rustaceanvim',                    version = vim.version.range('^6') },
    {
        src = 'ssh://git@ssh.github.com:443/ray-x/go.nvim',
        build = function() require('go.install').update_all_sync() end,
        check = function() return vim.fn.expand('~') .. '/go/bin/gofumpt' end
    },
    { src = 'ssh://git@ssh.github.com:443/ray-x/guihua.lua' },
    { src = 'ssh://git@ssh.github.com:443/ziglang/zig.vim' },
    { src = 'ssh://git@ssh.github.com:443/terrastruct/d2-vim' },

    -- dap
    { src = 'ssh://git@ssh.github.com:443/mfussenegger/nvim-dap' },
    { src = 'ssh://git@ssh.github.com:443/nvim-neotest/nvim-nio' },
    { src = 'ssh://git@ssh.github.com:443/rcarriga/nvim-dap-ui' },
}

vim.pack.add(plugins)

require('plugins.build')(plugins)
require('plugins.ui')
require('plugins.editor')
require('plugins.lsp')
require('plugins.completion')
require('plugins.copilot')
require('plugins.treesitter')
require('plugins.dap')
require('plugins.lang')
vim.pack.add(plugins)
