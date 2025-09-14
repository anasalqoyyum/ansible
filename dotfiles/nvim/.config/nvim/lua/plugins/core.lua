return {
  -- disable bufferline and indentscope
  { "akinsho/bufferline.nvim", enabled = false },

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
    "NMAC427/guess-indent.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {},
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>a", group = "ai", mode = { "n", "v" } },
        { "<leader>ao", group = "opencode", mode = { "n", "v" } },
        { "<leader>m", group = "multi-cursor", icon = "󰗧", mode = { "n", "v" } },
        { "<leader>r", group = "rulebook", icon = " ", mode = { "n", "v" } },
        { "<leader>o", group = "overseer", icon = " ", mode = { "n" } },
        { "<leader>T", group = "tips", icon = " ", mode = { "n" } },
        { "<leader>i", group = "i18n", icon = "", mode = { "n" } },
      },
    },
  },

  {
    "saxon1964/neovim-tips",
    version = "*", -- Only update on tagged releases
    dependencies = {
      "MunifTanjim/nui.nvim",
      "MeanderingProgrammer/render-markdown.nvim",
    },
    opts = {
      user_file = vim.fn.stdpath("config") .. "/neovim_tips/user_tips.md",
      user_tip_prefix = "[User] ",
      warn_on_conflicts = true,
      -- 0 = off, 1 = once per day, 2 = every startup
      daily_tip = 0,
    },
    keys = {
      {
        "<leader>To",
        "<cmd>NeovimTips<cr>",
        desc = "Neovim tips",
      },
      {
        "<leader>Te",
        "<cmd>NeovimTipsEdit<cr>",
        desc = "Edit your Neovim tips",
      },
      {
        "<leader>Ta",
        "<cmd>NeovimTipsAdd<cr>",
        desc = "Add your Neovim tip",
      },
      {
        "<leader>Tr",
        "<cmd>NeovimTipsRandom<cr>",
        desc = "Show random tip",
      },
    },
  },

  -- fix slow clipboard in WSL (win32yank is also works but sometimes freeze on my work laptop)
  {
    "bkoropoff/clipipe",
    enabled = vim.fn.has("wsl") == 1,
    opts = {},
  },
}
