return {
  {
    "stevearc/quicker.nvim",
    event = "FileType qf",
    ---@module "quicker"
    ---@type quicker.SetupOptions
    opts = {
      borders = {
        vert = "│",
        strong_header = "─",
        strong_cross = "┼",
        strong_end = "┤",
        soft_header = "╌",
        soft_cross = "╎",
        soft_end = "┆",
      },
      keys = {
        {
          ">",
          function()
            require("quicker").expand({ before = 2, after = 2, add_to_existing = true })
          end,
          desc = "Expand quickfix context",
        },
        {
          "<",
          function()
            require("quicker").collapse()
          end,
          desc = "Collapse quickfix context",
        },
      },
    },
  },

  {
    "kevinhwang91/nvim-bqf",
    event = "FileType qf",
    opts = {},
  },
}
