local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- configure Solang LSP
vim.lsp.config('solang', {
    on_attach = function(client)
        lspstatus.on_attach(client)
    end,
    capabilities = capabilities,
})

-- enable the server
vim.lsp.enable('solang')
