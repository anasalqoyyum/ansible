-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local DIFFVIEW_FILETYPES = {
  "DiffviewFiles",
  "DiffviewView",
  "DiffviewFileHistory",
}

local function is_diffview_buffer(buf)
  local ft = vim.bo[buf].filetype
  local bt = vim.bo[buf].buftype
  local name = vim.api.nvim_buf_get_name(buf)

  for _, diff_ft in ipairs(DIFFVIEW_FILETYPES) do
    if ft == diff_ft then
      return true
    end
  end

  if name:match("^diffview://") then
    return true
  end

  if bt == "nofile" and name:match("Diffview") then
    return true
  end

  return false
end

local function is_diffview_open()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if is_diffview_buffer(vim.api.nvim_win_get_buf(win)) then
      return true
    end
  end
  return false
end

local function toggle_diffview()
  if is_diffview_open() then
    vim.cmd("DiffviewClose")
  else
    vim.cmd("DiffviewOpen")
  end
end

Snacks.toggle({
  name = "Git Blame Line",
  get = function()
    return require("gitsigns.config").config.current_line_blame
  end,
  set = function(state)
    require("gitsigns").toggle_current_line_blame(state)
  end,
}):map("<leader>gu")

-- remap split window below
vim.keymap.set("n", "<leader>_", "<C-W>s", { desc = "Split Window Below", remap = true })

-- git diffview
vim.keymap.set("n", "<leader>gd", toggle_diffview, { desc = "Toggle Diff View" })
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

-- lspsaga
vim.keymap.set("n", "<leader>cp", "<Cmd>Lspsaga peek_definition<cr>", { desc = "Peek Definition" })
vim.keymap.set("n", "<leader>cP", "<Cmd>Lspsaga peek_type_definition<cr>", { desc = "Peek Type Definition" })

-- tabs (let's not disable this for now)
-- vim.keymap.del("n", "<leader><tab><tab>")
-- vim.keymap.del("n", "<leader><tab>l")
-- vim.keymap.del("n", "<leader><tab>o")
-- vim.keymap.del("n", "<leader><tab>f")
-- vim.keymap.del("n", "<leader><tab>]")
-- vim.keymap.del("n", "<leader><tab>d")
-- vim.keymap.del("n", "<leader><tab>[")
