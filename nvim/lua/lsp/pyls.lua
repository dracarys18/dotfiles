
local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- configure Python LSP
vim.lsp.config('pyls', {
    cmd = { "pyls" },
    on_attach = function(client)
        lspstatus.on_attach(client)
    end,
    capabilities = capabilities,
    filetypes = { "python" },
})

-- enable the server
vim.lsp.enable('pyls')
