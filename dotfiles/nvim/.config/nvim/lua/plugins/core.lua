return {
  -- disable bufferline and indentscope
  { "akinsho/bufferline.nvim", enabled = false },

  {
    "NMAC427/guess-indent.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "ai", mode = { "n", "v" } },
        { "<leader>m", group = "multi-cursor", icon = "󰗧", mode = { "n", "v" } },
        { "<leader>r", group = "rulebook", icon = " ", mode = { "n", "v" } },
        { "<leader>o", group = "overseer", icon = " ", mode = { "n" } },
        { "<leader>T", group = "tips", icon = " ", mode = { "n" } },
        { "<leader>i", group = "i18n", icon = "", mode = { "n" } },
      },
    },
  },

  {
    "chrisgrieser/nvim-early-retirement",
    event = "VeryLazy",
    opts = {},
  },

  -- may or may not broke the lsp
  {
    "zeioth/garbage-day.nvim",
    dependencies = "neovim/nvim-lspconfig",
    enabled = false,
    event = "VeryLazy",
    opts = {
      excluded_lsp_clients = {
        "copilot",
        "null-ls",
        "jdtls",
        "marksman",
        "lua_ls",
      },
    },
  },
}
