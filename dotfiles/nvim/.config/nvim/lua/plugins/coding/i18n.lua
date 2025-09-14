-- slow startup on repo with big i18n
return {
  {
    "yelog/i18n.nvim",
    enabled = false,
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
    -- prefer local/project config
    -- See: https://github.com/yelog/i18n.nvim?tab=readme-ov-file#-project-level-configuration-recommended
    opts = {},
    keys = {
      {
        "<leader>in",
        "<cmd>I18nNextLocale<CR>",
        desc = "Cycle i18n display language",
        mode = "n",
      },
      {
        "<leader>io",
        "<cmd>I18nToggleOrigin<CR>",
        desc = "Toggle i18n origin display",
        mode = "n",
      },
      {
        "<leader>id",
        function()
          require("i18n").i18n_definition()
        end,
        desc = "Jump to i18n definition",
        mode = "n",
      },
      {
        "<leader>ik",
        function()
          require("i18n").show_popup()
        end,
        desc = "i18n popup or signature help",
        mode = { "n", "i" },
      },
    },
  },
}
