local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

return require('lazy').setup({
    { "ellisonleao/glow.nvim", config = true, cmd = "Glow" },
    'samoshkin/vim-mergetool',
    'mhartington/formatter.nvim',
    -- 'christianrondeau/vim-base64',

    { 'tpope/vim-commentary',  lazy = false },
    {
        'tpope/vim-fugitive',
        cmd = { "Git", "Gdiffsplit", "Gvdiffsplit", "Gedit", "Gread", "Gwrite", "Ggrep", "Gbrowse", "GMove", "GDelete" }
    },
    'tpope/vim-repeat',
    'tpope/vim-speeddating',
    'tpope/vim-surround',
    'tpope/vim-vinegar',
    'tpope/vim-abolish',
    { 'yuttie/comfortable-motion.vim', lazy = false },
    -- 'ruanyl/vim-gh-line',
    -- 'b0o/SchemaStore.nvim',
    -- 'rcarriga/nvim-notify',
    'folke/todo-comments.nvim',
    -- 'ggandor/leap.nvim',
    { 'shortcuts/no-neck-pain.nvim',   version = "*" },
    -- { 'folke/zen-mode.nvim',         config = function() require('zen-mode').setup() end },
    -- { 'folke/twilight.nvim',         config = function() require('twilight').setup() end },
    {
        'pwntester/octo.nvim',
        cmd = "Octo",
        config = function()
            require(
                'octo').setup()
        end
    },
    {
        'catppuccin/nvim',
        lazy = false,
        name = 'catppuccin',
        config = function()
            require(
                'colorscheme')
        end
    },
    { 'folke/which-key.nvim',        config = function() require("which-key").setup() end },
    {
        'nvim-telescope/telescope.nvim',
        cmd = "Telescope",
        dependencies = { 'nvim-lua/plenary.nvim', 'nvim-telescope/telescope-ui-select.nvim',
            'nvim-telescope/telescope-fzf-native.nvim' }
    },
    -- {
    --     'utilyre/barbecue.nvim',
    --     event = "LspAttach",
    --     version = "*",
    --     config = function() require('barbecue').setup() end,
    --     dependencies = {
    --         'neovim/nvim-lspconfig',
    --         'SmiteshP/nvim-navic',
    --         'nvim-tree/nvim-web-devicons'
    --     },
    -- },
    {
        'williamboman/mason.nvim',
        cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall" },
        version = "^1.0.0",
        config = function()
            require("mason").setup({
                ui = {
                    icons = {
                        package_installed = "✓",
                        package_pending = "➜",
                        package_uninstalled = "✗"
                    }
                }
            })
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        version = "^1.0.0",
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "lua_ls", "pylsp", "gopls", "bashls", "clangd", "ts_ls", "zls", "terraformls", "rust_analyzer" },
                automatic_installation = true,
            })
        end,
        lazy = false
    },
    {
        'NTBBloodbath/galaxyline.nvim',
        branch = 'main',
        lazy = false,
        config = function() require('statusline') end,
        dependencies = { 'nvim-tree/nvim-web-devicons' }
    },
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        -- build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
        build = 'make',
        config = function()
            require('telescope').setup {
                defaults = {
                    initial_mode = 'insert',
                },
                extensions = {
                    fzf = {
                        fuzzy = true,                   -- false will only do exact matching
                        override_generic_sorter = true, -- override the generic sorter
                        override_file_sorter = true,    -- override the file sorter
                        case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
                    }
                }
            }
            require('telescope').load_extension('fzf')
        end,
    },
    {
        'nvim-telescope/telescope-ui-select.nvim',
        config = function()
            require("telescope").load_extension("ui-select")
        end
    },
    { 'norcalli/nvim-colorizer.lua', config = function() require 'colorizer'.setup() end, },
    -- lsp
    -- use { 'onsails/lspkind-nvim', config = function() require'lspkind'.init() end, }
    -- {
    {
        "folke/trouble.nvim",
        opts = {}, -- for default options, refer to the configuration section for custom setup.
        cmd = "Trouble",
        keys = {
            {
                "<leader>o",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Buffer Diagnostics (Trouble)",
            },
            {
                "<leader>cs",
                "<cmd>Trouble symbols toggle focus=false<cr>",
                desc = "Symbols (Trouble)",
            },
            {
                "<leader>cl",
                "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
                desc = "LSP Definitions / references / ... (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Location List (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Quickfix List (Trouble)",
            },
        },
    },
    {
        'neovim/nvim-lspconfig',
        ft = { "toml", "lua" },
        config = function()
            require(
                "lsp")
        end,
    },
    {
        'nvim-lua/lsp-status.nvim',
        event = "LspAttach"
    },
    {
        'ray-x/lsp_signature.nvim',
        event = "LspAttach",
        config = function()
            require("lsp_signature").setup({
                floating_window_above_cur_line = true,
            })
        end,
    },
    {
        'terrastruct/d2-vim',
        ft = "d2",
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
            "hrsh7th/cmp-cmdline",
            "L3MON4D3/LuaSnip",            -- Snippet engine
            "saadparwaiz1/cmp_luasnip",    -- Snippet completions
            "rafamadriz/friendly-snippets" -- Optional snippet collection
        },
        config = require("setup.cmp")
    },
    {
        'akinsho/bufferline.nvim',
        dependencies =
        'nvim-tree/nvim-web-devicons'
    },
    {
        'lewis6991/gitsigns.nvim',
        lazy = false,
        config = function() require('gitsigns').setup { current_line_blame = true, } end
    },
    {
        'stevearc/oil.nvim',
        opts = {},
        -- Optional dependencies
        dependencies = { "nvim-tree/nvim-web-devicons" },
        lazy = false,
        config = function() require('oil').setup() end
    },
    -- use 'airblade/vim-rooter'
    -- use({
    --     "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
    --     config = function()
    --         require("lsp_lines").setup()
    --     end,
    -- })
    {
        "ray-x/go.nvim",
        dependencies = { -- optional packages
            "ray-x/guihua.lua",
            "neovim/nvim-lspconfig",
            "nvim-treesitter/nvim-treesitter",
        },
        lazy = false,
        config = function()
            require("go").setup()
        end,
        event = { "CmdlineEnter" },
        ft = { "go", 'gomod' },
        build = ':lua require("go.install").update_all_sync()' -- if you need to install/update all binaries
    }
    ,
    {
        "giusgad/pets.nvim",
        dependencies = { "MunifTanjim/nui.nvim", "giusgad/hologram.nvim" },
        lazy = true,
        config = function() require "pets".setup() end,
    },
    {
        'lukas-reineke/indent-blankline.nvim',
        config = function()
            require("indent_blankline").setup {
                show_end_of_line = true,
            }
        end
    },
    {
        'sindrets/diffview.nvim',
        cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles", "DiffviewRefresh" },
        dependencies = 'nvim-lua/plenary.nvim'
    },
    {
        'akinsho/toggleterm.nvim',
        cmd = "ToggleTerm",
        lazy = false,
        config = function() require 'setup.toggleterm' end,
    },
    -- {
    --     'glepnir/dashboard-nvim',
    --     config = function() require 'setup.dashboard' end,
    -- },

    {
        'nvim-treesitter/nvim-treesitter',
        branch = "master",
        build = ':TSUpdate'
    },
    {
        'nvim-treesitter/nvim-treesitter-context',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
    },
    {
        'mrcjkb/rustaceanvim',
        version = '^6', -- Recommended
        ft = { 'rust' },
    },
    {
        "zbirenbaum/copilot.lua",
        cmd = "Copilot",
        event = "InsertEnter",
        config = function()
            require("copilot").setup({
                suggestion = { enabled = false },
                panel = { enabled = false },
                filetypes = {
                    rust = true,   -- allow specific filetype
                    ["*"] = false, -- disable for all other filetypes and ignore default `filetypes`
                }
            })
        end,
    },
    {
        "zbirenbaum/copilot-cmp",
        lazy = false,
        config = function()
            require("copilot_cmp").setup()
        end
    },
    {
        "rcarriga/nvim-dap-ui",
        dependencies = { "mfussenegger/nvim-dap" },
        config = function() require("dapui").setup() end
    },
    {
        'simrat39/symbols-outline.nvim',
        cmd = "SymbolsOutline",
        config = function()
            require('symbols-outline').setup()
        end
    },
    {
        "glepnir/lspsaga.nvim",
        event = "LspAttach",
        config = function()
            require("lspsaga").setup({})
        end,
        dependencies = {
            { "nvim-tree/nvim-web-devicons" },
            --Please make sure you install markdown and markdown_inline parser
            { "nvim-treesitter/nvim-treesitter" }
        }
    },
    {
        'j-hui/fidget.nvim',
        event = "LspAttach",
        config = function()
            require("fidget").setup({})
        end
    },
}, {
    defaults = {
        lazy = true,
    }
});
