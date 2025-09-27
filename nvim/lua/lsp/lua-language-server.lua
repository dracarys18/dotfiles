local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- configure Lua LSP
vim.lsp.config('lua_ls', {
    cmd = { "lua-language-server" },
    on_attach = function(client)
        lspstatus.on_attach(client)
    end,
    capabilities = capabilities,
    filetypes = { "lua" },
    log_level = 2,
    settings = {
        Lua = {
            diagnostics = {
                globals = { 'vim' },
            },
            telemetry = {
                enable = false,
            },
            formatting = {
                end_of_line = 'lf',
            },
        }
    },
})

-- enable the server
vim.lsp.enable('lua_ls')
