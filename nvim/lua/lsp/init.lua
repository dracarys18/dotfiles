local lspstatus = require('lsp-status')

require 'lsp.lua-language-server'
require 'lsp.clangd'

-- build capabilities (blink.cmp augments if available)
local base_caps = vim.tbl_deep_extend('force',
    vim.lsp.protocol.make_client_capabilities(),
    lspstatus.capabilities
)
local ok, blink = pcall(require, 'blink.cmp')
local capabilities = ok and blink.get_lsp_capabilities(base_caps) or base_caps

-- global defaults for all servers
vim.lsp.config('*', {
    capabilities = capabilities,
    on_attach    = lspstatus.on_attach,
})

-- per-language configs
vim.lsp.config('ocamllsp', {})
vim.lsp.config('gopls', {})
vim.lsp.config('zls', {
    filetypes            = { 'zig', 'zon' },
    single_file_support  = true,
    root_dir             = vim.fs.root(0, { 'build.zig', '.git' }) or vim.uv.cwd(),
    zig_exe_path         = '/opt/homebrew/bin/zig',
    settings = {
        zls = {
            enable_inlay_hints                 = true,
            inlay_hints_hide_redundant_param_names = true,
            enable_ast_check_diagnostics       = true,
            warn_style                         = true,
            semantic_tokens                    = 'partial',
        },
    },
})

-- mason-lspconfig: install servers + set up handlers (single call)
require('mason-lspconfig').setup {
    ensure_installed = {
        'lua_ls', 'pylsp', 'gopls', 'bashls', 'clangd',
        'ts_ls', 'zls', 'terraformls', 'rust_analyzer',
    },
    automatic_installation = true,
    handlers = {
        function(server_name)
            if not server_name:match('^rust') then
                vim.lsp.enable(server_name)
            end
        end,
    },
}

vim.lsp.enable({ 'ocamllsp', 'gopls', 'zls' })
