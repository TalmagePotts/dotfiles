return {
    'nvim-telescope/telescope.nvim', tag = '0.1.6',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
        local builtin = require('telescope.builtin')

        -- Find Files --
        vim.keymap.set({'n', 'v'}, '<leader>ff', builtin.find_files, {})
        
        -- Find String --
        vim.keymap.set({'n', 'v'}, '<leader>fg', builtin.live_grep, {})

        -- Find Buffers --
        vim.keymap.set({'n', 'v'}, '<leader>fb', builtin.buffers, {})

        -- Find Help Tags --
        vim.keymap.set({'n', 'v'}, '<leader>fh', builtin.help_tags, {})
    end
}
