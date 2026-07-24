return {
  "lukas-reineke/headlines.nvim",
  dependencies = "nvim-treesitter/nvim-treesitter", -- headlines uses treesitter
  config = function()
    require("headlines").setup()
  end,
  ft = { "markdown", "text" }, -- Only load for markdown and text files
}