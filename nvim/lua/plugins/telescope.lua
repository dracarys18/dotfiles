require('telescope').setup {
    defaults = { initial_mode = 'insert' },
    extensions = {
        fzf = {
            fuzzy                   = true,
            override_generic_sorter = true,
            override_file_sorter    = true,
            case_mode               = 'smart_case',
        },
    },
}

require('telescope').load_extension('fzf')
require('telescope').load_extension('ui-select')
