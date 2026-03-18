if vim.g.copilot_flavor ~= "cursor" then
  return {}
end

return {
  {
    "cursortab/cursortab.nvim",
    lazy = false, -- The server is already lazy loaded
    build = "cd server && go build",
    config = function()
      require("cursortab").setup({
        provider = {
          type = "mercuryapi",
          api_key_env = "MERCURY_AI_TOKEN",
        },
      })
    end,
  },
}
