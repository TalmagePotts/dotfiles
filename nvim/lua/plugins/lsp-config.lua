return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup()
        end
    },
    {
        "williamboman/mason-lspconfig.nvim",
        config = function()
            require("mason-lspconfig").setup({})
        end
    },
    {
        "neovim/nvim-lspconfig",
        config = function()
            local lspconfig = require("lspconfig")
            lspconfig.lua_ls.setup({})
            -- lspconfig.tsserver.setup({})
            -- lspconfig.markdown_oxide.setup({})
            -- lspconfig.jsonls.setup({})
            -- lspconfig.html.setup({})
            -- lspconfig.arduino_language_server.setup({})
            -- lspconfig.bashls.setup({})
            -- lspconfig.clangd.setup({})
            -- lspconfig.csharp_ls.setup({})
            -- lspconfig.cssls.setup({})
            -- lspconfig.sqlls.setup({})

            vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
            vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
        end
    }
}
