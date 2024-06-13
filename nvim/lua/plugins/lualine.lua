return {
    "nvim-lualine/lualine.nvim",
    config = function()
        require('lualine').setup({
            options = {
                theme = 'codedark'
            }
        })
        vim.opt.laststatus = 3 -- Always show statusline
        vim.opt.cmdheight = 0 -- Makes it so that command and lualine share the same line
    end
}

