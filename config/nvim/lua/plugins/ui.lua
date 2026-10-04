require('colorscheme')
require('statusline')

require('which-key').setup()
require('todo-comments').setup()
require('colorizer').setup()
require('fidget').setup({})

require('bufferline').setup {
    options = { diagnostics = 'nvim_lsp' },
}
