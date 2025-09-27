local capabilities = require('cmp_nvim_lsp').default_capabilities()
local lspstatus = require('lsp-status')

-- configure clangd
vim.lsp.config('clangd', {
    capabilities = capabilities,
    cmd = { "clangd" },
    filetypes = { "c", "cpp", "objc", "objcpp" },
    root_dir = vim.fs.find({ "compile_commands.json", "compile_flags.txt", ".git" }, { upward = true })[1]
        or vim.loop.cwd(),
    single_file_support = true,
})

-- enable clangd
vim.lsp.enable('clangd')
