local lspconfig = require 'lspconfig'
local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

lspconfig.bashls.setup {
    cmd = { "bash-language-server", "start" },
    on_attach = function(client)
        lspstatus.on_attach(client)
        return
    end,
    capabilities = capabilities,
    filetypes = { "sh" },
}
