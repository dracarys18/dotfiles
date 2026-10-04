local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- configure TypeScript/JavaScript LSP
vim.lsp.config('ts_ls', {
    on_attach = function(client)
        lspstatus.on_attach(client)
    end,
    capabilities = capabilities,
})

-- enable the server
vim.lsp.enable('ts_ls')
