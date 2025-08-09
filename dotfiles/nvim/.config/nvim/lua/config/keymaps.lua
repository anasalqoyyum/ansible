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

-- remap split window below
vim.keymap.set("n", "<leader>_", "<C-W>s", { desc = "Split Window Below", remap = true })

-- git diffview
vim.keymap.set("n", "<leader>gd", "<cmd>DiffviewOpen<cr>", { desc = "Open Diff View" })
vim.keymap.set("n", "<leader>gD", "<cmd>DiffviewClose<cr>", { desc = "Close Diff View" })
vim.keymap.set("n", "<leader>gL", "<cmd>DiffviewFileHistory<cr>", { desc = "Diff Repo History" })
vim.keymap.set("n", "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", { desc = "Diff Current File History" })
vim.keymap.set("n", "<leader>g.", "<Cmd>.DiffviewFileHistory --follow<CR>", { desc = "Diff Line history" })
vim.keymap.set("v", "<leader>gv", "<Esc><Cmd>'<,'>DiffviewFileHistory --follow<CR>", { desc = "Diff Range history" })
vim.keymap.set("n", "<leader>gR", "<cmd>DiffviewRefresh<cr>", { desc = "Git Diff Refresh" })

-- oil.nvim
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
vim.keymap.set("n", "<leader>-", "<CMD>Oil --float<CR>", { desc = "Open parent directory (float)" })

-- avante toggle suggestion and debug
vim.keymap.del("n", "<leader>as")
vim.keymap.del("n", "<leader>ad")

-- tabs (let's not disable this for now)
-- vim.keymap.del("n", "<leader><tab><tab>")
-- vim.keymap.del("n", "<leader><tab>l")
-- vim.keymap.del("n", "<leader><tab>o")
-- vim.keymap.del("n", "<leader><tab>f")
-- vim.keymap.del("n", "<leader><tab>]")
-- vim.keymap.del("n", "<leader><tab>d")
-- vim.keymap.del("n", "<leader><tab>[")
