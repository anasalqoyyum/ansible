-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local lsp_restart = require("custom.lsp-restart")
local yank = require("custom.yank")

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

-- lsp peek definition
vim.keymap.set(
  "n",
  "<leader>cp",
  "<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
  { noremap = true, desc = "Peek Definition" }
)
vim.keymap.set(
  "n",
  "<leader>cP",
  "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>",
  { noremap = true, desc = "Peek Type Definition" }
)

-- Toggle syntax highlighting and related render features
Snacks.toggle({
  name = "Highlighting",
  get = function()
    -- Check current buffer Treesitter highlight status and render-markdown state
    local ts_on = vim.b.ts_highlight
    local render_on = require("render-markdown").get()
    return ts_on and render_on
  end,
  set = function(state)
    if state then
      vim.treesitter.start()
      require("treesitter-context").enable()
      require("render-markdown").set(true)
    else
      vim.treesitter.stop()
      require("treesitter-context").disable()
      require("render-markdown").set(false)
    end
  end,
}):map("<leader>uH")

vim.keymap.set("n", "<leader>cL", function()
  lsp_restart.restart_lsp()
end, { desc = "[L]SP Restart" })

vim.keymap.set("n", "<leader>ya", function()
  yank.yank_path(yank.get_buffer_absolute(), "absolute")
end, { desc = "[Y]ank [A]bsolute path to clipboard" })

vim.keymap.set("n", "<leader>yr", function()
  yank.yank_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank [R]elative path to clipboard" })

vim.keymap.set("v", "<leader>ya", function()
  yank.yank_visual_with_path(yank.get_buffer_absolute(), "absolute")
end, { desc = "[Y]ank selection with [A]bsolute path" })

vim.keymap.set("v", "<leader>yr", function()
  yank.yank_visual_with_path(yank.get_buffer_cwd_relative(), "relative")
end, { desc = "[Y]ank selection with [R]elative path" })

--[[ Git diff (vscode-diff)
vim.keymap.set('n', '<leader>dd', '<cmd>:CodeDiff<cr>', { desc = 'Git [d]iff' })
vim.keymap.set('n', '<leader>do', function()
  local remotes_output = vim.fn.system 'git remote'
  local upstream_exists = remotes_output:find 'upstream' ~= nil
  local remote = upstream_exists and 'upstream' or 'origin'
  vim.cmd(':CodeDiff ' .. remote .. '/main HEAD')
end, { desc = 'Git [d]iff against upstream/main or origin/main' })
--]]
