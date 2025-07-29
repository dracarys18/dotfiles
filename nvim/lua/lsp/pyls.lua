local lspconfig = require 'lspconfig'
local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.pyls.setup {
    cmd = { "pyls" },
    on_attach = function(client)
        lspstatus.on_attach(client)
        return
    end,
    capabilities = capabilities,
    filetypes = { "python" },
}
