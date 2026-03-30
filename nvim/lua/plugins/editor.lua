require('oil').setup()

require('toggleterm').setup {
    size          = 70,
    open_mapping  = [[<c-\>]],
    hide_numbers  = true,
    shade_terminals = true,
    shading_factor  = '1',
    start_in_insert = true,
    persist_size    = true,
    direction       = 'float',
    close_on_exit   = true,
    shell           = vim.o.shell,
    float_opts = {
        border   = 'single',
        width    = 200,
        height   = 50,
        winblend = 3,
        highlights = { border = 'Normal', background = 'Normal' },
    },
}

require('gitsigns').setup { current_line_blame = true }

require('trouble').setup({})
