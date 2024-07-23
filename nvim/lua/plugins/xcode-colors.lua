return {
    'arzg/vim-colors-xcode',
    config = function()
        -- Set the background color to transparent
        -- Set the background color to transparent for various highlight groups
        vim.cmd("highlight Normal ctermbg=none guibg=none")
        vim.cmd("highlight NonText ctermbg=none guibg=none")
        vim.cmd("highlight LineNr ctermbg=none guibg=none")
        vim.cmd("highlight Folded ctermbg=none guibg=none")
        vim.cmd("highlight EndOfBuffer ctermbg=none guibg=none")
        vim.cmd("highlight SignColumn ctermbg=none guibg=none")
        vim.cmd("highlight StatusLineNC ctermbg=none guibg=none")
        vim.cmd("highlight VertSplit ctermbg=none guibg=none")
        vim.cmd("highlight TabLineFill ctermbg=none guibg=none")
        -- Change the color of the line numbers
        vim.cmd("highlight LineNr ctermfg=white guifg=#ffffff")
    end
}
