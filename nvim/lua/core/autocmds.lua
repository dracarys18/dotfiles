-- persist folds/views across sessions
vim.api.nvim_create_autocmd({ 'BufWinLeave', 'BufLeave', 'BufWritePost', 'BufHidden', 'QuitPre' }, {
    pattern = '?*',
    nested = true,
    command = 'silent! mkview!',
})
vim.api.nvim_create_autocmd('BufWinEnter', {
    pattern = '?*',
    command = 'silent! loadview',
})

-- solidity filetype
vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
    pattern = '*.sol',
    command = 'set ft=solidity',
})

-- zig: format on save via LSP
vim.api.nvim_create_autocmd('BufWritePre', {
    pattern = { '*.zig', '*.zon' },
    callback = function() vim.lsp.buf.format() end,
})
