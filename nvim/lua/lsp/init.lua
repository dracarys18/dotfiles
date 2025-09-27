local lspstatus = require('lsp-status')

require 'lsp.lua-language-server'
require 'lsp.clangd'

-- capabilities for nvim-cmp
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- global defaults for all servers
vim.lsp.config('*', {
    capabilities = capabilities,
    on_attach = lspstatus.on_attach,
})

-- ocaml
vim.lsp.config('ocamllsp', {})

-- go
vim.lsp.config('gopls', {})

-- zig (zls)
vim.lsp.config('zls', {
    filetypes = { "zig", "zon" },
    single_file_support = true,
    root_dir = vim.fs.root(0, { "build.zig", ".git" }) or vim.uv.cwd(),
    zig_exe_path = "/opt/homebrew/bin/zig",
    settings = {
        zls = {
            enable_inlay_hints = true,
            inlay_hints_hide_redundant_param_names = true,
            enable_ast_check_diagnostics = true,
            warn_style = true,
            semantic_tokens = "partial",
        },
    },
})

-- mason-lspconfig integration
require('mason-lspconfig').setup({
    handlers = {
        function(server_name)
            if not server_name:match("^rust") then
                vim.lsp.enable(server_name)
            end
        end,
    },
})

-- explicitly enable the servers you want
vim.lsp.enable({ 'ocamllsp', 'gopls', 'zls' })
-- add 'jsonls' if you uncommented its config

-- completion options
vim.o.completeopt = "menuone,noselect"
vim.o.clipboard = "unnamedplus"

-- omnifunc for LSP-based completion
vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

-- bufferline with diagnostics
require("bufferline").setup {
    options = { diagnostics = "nvim_lsp" },
}
