return {
  -- disable bufferline and indentscope
  { "akinsho/bufferline.nvim", enabled = false },

  -- probably not needed on pure unix (so only WSL is needed due to slow clipboard)
  -- only needed when yanky.nvim enabled I guess
  -- {
  --   "EtiamNullam/deferred-clipboard.nvim",
  --   event = "VeryLazy",
  --   opts = {
  --     lazy = true,
  --   },
  -- },

  -- use jk for esc in insert mode
  {
    "max397574/better-escape.nvim",
    config = function()
      require("better_escape").setup({
        default_mappings = false,
        mappings = {
          i = {
            j = { k = "<Esc>" },
          },
        },
      })
    end,
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "ai" },
        { "<leader>m", group = "multi-cursor", icon = "󰗧" },
      },
    },
  },
}
