-- lua/plugins.lua
-- Migrated from lazy.nvim to vim.pack (Neovim 0.12+)
--
-- NOTE: After first install, run these build steps manually:
--   telescope-fzf-native : cd {data}/site/pack/core/opt/telescope-fzf-native.nvim && make
--   nvim-treesitter      : :TSUpdate
--   go.nvim              : :lua require("go.install").update_all_sync()
--
-- Update plugins : vim.pack.update()
-- Lockfile       : {config}/nvim-pack-lock.json  (commit this)

vim.pack.add({
    -- Core dependencies
    { src = 'ssh://git@ssh.github.com:443/nvim-lua/plenary.nvim' },
    { src = 'ssh://git@ssh.github.com:443/nvim-tree/nvim-web-devicons' },

    -- Colorscheme
    { src = 'ssh://git@ssh.github.com:443/catppuccin/nvim', name = 'catppuccin' },

    -- tpope essentials
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-commentary' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-repeat' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-speeddating' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-surround' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-abolish' },
    { src = 'ssh://git@ssh.github.com:443/tpope/vim-fugitive' },

    -- Motion / editing
    { src = 'ssh://git@ssh.github.com:443/samoshkin/vim-mergetool' },

    -- UI
    { src = 'ssh://git@ssh.github.com:443/nvim-lualine/lualine.nvim' },
    { src = 'ssh://git@ssh.github.com:443/akinsho/bufferline.nvim' },
    { src = 'ssh://git@ssh.github.com:443/j-hui/fidget.nvim' },
    { src = 'ssh://git@ssh.github.com:443/folke/which-key.nvim' },
    { src = 'ssh://git@ssh.github.com:443/folke/todo-comments.nvim' },
    { src = 'ssh://git@ssh.github.com:443/norcalli/nvim-colorizer.lua' },

    -- File navigation / tools
    { src = 'ssh://git@ssh.github.com:443/stevearc/oil.nvim' },
    { src = 'ssh://git@ssh.github.com:443/akinsho/toggleterm.nvim' },

    -- Telescope
    { src = 'ssh://git@ssh.github.com:443/nvim-telescope/telescope.nvim' },
    { src = 'ssh://git@ssh.github.com:443/nvim-telescope/telescope-fzf-native.nvim' }, -- build: make
    { src = 'ssh://git@ssh.github.com:443/nvim-telescope/telescope-ui-select.nvim' },

    -- LSP
    { src = 'ssh://git@ssh.github.com:443/neovim/nvim-lspconfig' },
    { src = 'ssh://git@ssh.github.com:443/nvim-lua/lsp-status.nvim' },
    { src = 'ssh://git@ssh.github.com:443/williamboman/mason.nvim',           version = vim.version.range('^1.0.0') },
    { src = 'ssh://git@ssh.github.com:443/williamboman/mason-lspconfig.nvim', version = vim.version.range('^1.0.0') },
    { src = 'ssh://git@ssh.github.com:443/glepnir/lspsaga.nvim' },
    { src = 'ssh://git@ssh.github.com:443/folke/trouble.nvim' },

    -- Completion
    { src = 'ssh://git@ssh.github.com:443/saghen/blink.cmp', version = vim.version.range('1.*') },

    -- Copilot (inline suggestions)
    { src = 'ssh://git@ssh.github.com:443/zbirenbaum/copilot.lua' },

    -- Git
    { src = 'ssh://git@ssh.github.com:443/lewis6991/gitsigns.nvim' },
    { src = 'ssh://git@ssh.github.com:443/sindrets/diffview.nvim' },

    -- Treesitter
    { src = 'ssh://git@ssh.github.com:443/nvim-treesitter/nvim-treesitter',         version = 'master' }, -- build: :TSUpdate
    { src = 'ssh://git@ssh.github.com:443/nvim-treesitter/nvim-treesitter-context' },

    -- Language specific
    { src = 'ssh://git@ssh.github.com:443/mrcjkb/rustaceanvim',  version = vim.version.range('^6') },
    { src = 'ssh://git@ssh.github.com:443/ray-x/go.nvim' },      -- build: :lua require("go.install").update_all_sync()
    { src = 'ssh://git@ssh.github.com:443/ray-x/guihua.lua' },
    { src = 'ssh://git@ssh.github.com:443/ziglang/zig.vim' },
    { src = 'ssh://git@ssh.github.com:443/terrastruct/d2-vim' },

    -- DAP
    { src = 'ssh://git@ssh.github.com:443/mfussenegger/nvim-dap' },
    { src = 'ssh://git@ssh.github.com:443/nvim-neotest/nvim-nio' },
    { src = 'ssh://git@ssh.github.com:443/rcarriga/nvim-dap-ui' },


})

-- ── Colorscheme ───────────────────────────────────────────────────────────────
require('colorscheme')

-- ── Status line ───────────────────────────────────────────────────────────────
require("statusline")

-- ── UI ────────────────────────────────────────────────────────────────────────
require("which-key").setup()
require("todo-comments").setup()
require('colorizer').setup()
require('oil').setup()
require('setup.toggleterm')

-- ── Telescope ─────────────────────────────────────────────────────────────────
require('telescope').setup {
    defaults = { initial_mode = 'insert' },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        }
    }
}
require('telescope').load_extension('fzf')
require('telescope').load_extension("ui-select")

-- ── Mason ─────────────────────────────────────────────────────────────────────
require("mason").setup({
    ui = {
        icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
        }
    }
})
require("mason-lspconfig").setup({
    ensure_installed = { "lua_ls", "pylsp", "gopls", "bashls", "clangd", "ts_ls", "zls", "terraformls", "rust_analyzer" },
    automatic_installation = true,
})

-- ── LSP ───────────────────────────────────────────────────────────────────────
require("lsp")

require("fidget").setup({})
require("lspsaga").setup({})
require("trouble").setup({})

-- ── Completion ────────────────────────────────────────────────────────────────
require('blink.cmp').setup({
    keymap = { preset = 'default' },
    appearance = { nerd_font_variant = 'mono' },
    sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets' },
    },
    completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
    },
    signature = { enabled = true },
})

-- ── Git ───────────────────────────────────────────────────────────────────────
require('gitsigns').setup { current_line_blame = true }

-- ── Go ────────────────────────────────────────────────────────────────────────
require("go").setup()

-- ── Copilot ───────────────────────────────────────────────────────────────────
require("copilot").setup({
    suggestion = {
        enabled = true,
        auto_trigger = true,
        keymap = { accept = "<M-l>", next = "<M-]>", prev = "<M-[>", dismiss = "<M-e>" },
    },
    panel = { enabled = false },
    filetypes = {
        rust = true,
        go = true,
        zig = true,
        ml = true,
        ["*"] = false,
    }
})

-- ── DAP ───────────────────────────────────────────────────────────────────────
require("dapui").setup()


