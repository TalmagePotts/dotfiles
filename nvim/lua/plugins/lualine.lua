return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "skwee357/nvim-prose",
    },
    config = function()
        local prose = require("nvim-prose")

        require("nvim-prose").setup({
            wpm = 200.0,
            filetypes = { "markdown", "text", "tex", "rst", "txt", "swift", "lua" },
            placeholders = {
                words = "words",
                minutes = "min",
            },
        })

        require("lualine").setup({
            options = {
                theme = "codedark",
            },
            sections = {
                lualine_x = {
                    { prose.word_count,   cond = prose.is_available },
                    { prose.reading_time, cond = prose.is_available },
                },
            },
        })
        vim.opt.laststatus = 3 -- Always show statusline
        vim.opt.cmdheight = 0 -- Makes it so that command and lualine share the same line
    end,
}
