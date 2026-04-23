require('copilot').setup {
    suggestion = { enabled = false },
    panel     = { enabled = false },
    filetypes = {
        rust = true,
        go   = true,
        zig  = true,
        ml   = true,
        ['*'] = false,
    },
}
