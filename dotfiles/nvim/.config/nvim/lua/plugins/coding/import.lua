return {
  {
    "piersolenski/import.nvim",
    event = "VeryLazy",
    dependencies = {
      "folke/snacks.nvim",
    },
    opts = {
      picker = "snacks",
    },
    keys = {
      {
        "<leader>ci",
        function()
          require("import").pick()
        end,
        desc = "Pick Import",
      },
    },
  },
}
