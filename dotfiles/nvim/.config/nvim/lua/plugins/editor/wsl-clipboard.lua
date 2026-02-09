return {
  {
    "lmgraf/wsl-clipboard.nvim",
    enabled = vim.fn.has("wsl") == 1,
    opts = {
      mode = "sync", -- options: "system", "sync", "focus"
    },
  },
}
