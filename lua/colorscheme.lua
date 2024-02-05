local vim = vim
vim.o.termguicolors = true

require("catppuccin").setup {
    flavour = "mocha", -- latte, frappe, macchiato, mocha
    term_colors = true,
    transparent_background = false,
    no_italic = false,
    no_bold = false,
    styles = {
        comments = {},
        conditionals = {},
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
    },
    color_overrides = {
        mocha = {
            base = "#000000",
            mantle = "#000000",
            crust = "#000000",
        },
    },
    highlight_overrides = {
        mocha = function(C)
            return {
                TabLineSel = { bg = C.pink },
                CmpBorder = { fg = C.surface2 },
                Pmenu = { bg = C.none },
                TelescopeBorder = { link = "FloatBorder" },
            }
        end,
    },
}

vim.cmd.colorscheme "catppuccin"
-- local colors = {
--     black = '#181819',
--     bg0   = '#2c2e34',
--     bg1   = '#30323a',
--     bg2   = '#363944',
--     bg3   = '#3b3e48',
--     bg4   = '#414550',

--     bg_red   = '#ff6077',
--     diff_red = '#55393d',

--     bg_green   = '#a7df78',
--     diff_green = '#394634',

--     bg_blue   = '#85d3f2',
--     diff_blue = '#354157',

--     diff_yellow = '#4e432f',
--     fg          = '#e2e2e3',

--     red    = '#fc5d7c',
--     orange = '#f39660',
--     yellow = '#e7c664',
--     green  = '#9ed072',
--     blue   = '#76cce0',
--     purple = '#b39df3',
--     grey   = '#7f8490',
--     none   = 'NONE',
-- }

-- -- Override some colors
-- vim.cmd('hi Normal guibg=' .. colors.black)
-- vim.cmd('hi NormalNC guibg=' .. colors.black)
-- vim.cmd('hi EndOfBuffer guibg=' .. colors.black)
-- -- vim.cmd('hi ToggleTerm1Buffer guibg='..colors.black)
-- vim.cmd('hi NonText guibg=' .. colors.black)
