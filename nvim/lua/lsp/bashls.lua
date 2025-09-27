local lspstatus = require('lsp-status')
local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- configure bashls
vim.lsp.config('bashls', {
    cmd = { "bash-language-server", "start" },
    on_attach = function(client)
        lspstatus.on_attach(client)
    end,
    capabilities = capabilities,
    filetypes = { "sh" },
})

-- enable bashls
vim.lsp.enable('bashls')
