return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    -- Disable conform.nvim for markdown files to prevent conflicts
    -- with other markdown-specific formatting plugins.
    opts.formatters_by_ft = {
      markdown = { "none" },
    }
  end,
}