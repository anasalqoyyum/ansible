if vim.g.ai_chat ~= "sidekick" then
  return {}
end

return {
  -- copilot-language-server (disabled in blink tho)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        copilot = {},
      },
    },
  },

  {
    "folke/sidekick.nvim",
    event = "VeryLazy",
    opts = function()
      -- Accept inline suggestions or next edits
      LazyVim.cmp.actions.ai_nes = function()
        local Nes = require("sidekick.nes")
        if Nes.have() and (Nes.jump() or Nes.apply()) then
          return true
        end
      end
    end,
    keys = {
      -- nes is also useful in normal mode
      { "<tab>", LazyVim.cmp.map({ "ai_nes" }, "<tab>"), mode = { "n" }, expr = true },
      { "<leader>a", "", desc = "+ai", mode = { "n", "v" } },
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ name = "opencode", focus = true })
        end,
        mode = { "n" },
        desc = "Sidekick Toggle",
      },
      {
        "<leader>an",
        function()
          require("sidekick.cli").select_tool()
        end,
        mode = { "n" },
        desc = "Sidekick New Tool",
      },
      {
        "<c-.>",
        function()
          require("sidekick.cli").focus()
        end,
        mode = { "n", "x", "i", "t" },
        desc = "Sidekick Switch Focus",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").select_prompt()
        end,
        desc = "Sidekick Ask Prompt",
        mode = { "n", "v" },
      },
    },
  },
}
