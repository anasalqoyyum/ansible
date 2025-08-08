-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

Snacks.toggle({
  name = "Git Blame Line",
  get = function()
    return require("gitsigns.config").config.current_line_blame
  end,
  set = function(state)
    require("gitsigns").toggle_current_line_blame(state)
  end,
}):map("<leader>uB")

-- delete unused keymap
-- avante toggle suggestion and debug
vim.keymap.del("n", "<leader>as")
vim.keymap.del("n", "<leader>ad")

-- tabs (let's not disable this for now, and only disable new tab)
-- vim.keymap.del("n", "<leader><tab>l")
-- vim.keymap.del("n", "<leader><tab>o")
-- vim.keymap.del("n", "<leader><tab>f")
vim.keymap.del("n", "<leader><tab><tab>")
-- vim.keymap.del("n", "<leader><tab>]")
-- vim.keymap.del("n", "<leader><tab>d")
-- vim.keymap.del("n", "<leader><tab>[")

-- git diffview
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open Git Diff View" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close Git Diff View" })
vim.keymap.set("n", "<leader>gR", "<cmd>DiffviewRefresh<cr>", { desc = "Git Diff Refresh" })
vim.keymap.set("n", "<leader>gL", "<cmd>DiffviewFileHistory<cr>", { desc = "Git Diff Log" })
vim.keymap.set("n", "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", { desc = "Git Diff Current File History" })
