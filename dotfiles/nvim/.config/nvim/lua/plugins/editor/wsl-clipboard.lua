return {
  {
    "lmgraf/wsl-clipboard.nvim",
    enabled = false,
    -- enabled = vim.fn.has("wsl") == 1,
    opts = {
      mode = "sync", -- options: "system", "sync", "focus"
    },
  },
}
