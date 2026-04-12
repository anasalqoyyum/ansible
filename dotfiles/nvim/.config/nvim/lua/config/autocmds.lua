-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- needed for eslint_d to work
vim.env.ESLINT_D_PPID = vim.fn.getpid()

local formatter_data = {
  prettierd = {
    ".prettierrc",
    ".prettierrc.json",
    ".prettierrc.yml",
    ".prettierrc.yaml",
    ".prettierrc.json5",
    ".prettierrc.js",
    ".prettierrc.cjs",
    ".prettierrc.mjs",
    ".prettierrc.toml",
    "prettier.config.js",
    "prettier.config.cjs",
    "prettier.config.mjs",
  },
  -- eslint = {
  --   ".eslintrc",
  --   ".eslintrc.json",
  --   "eslint.config.mjs",
  -- },
  biome = {
    "biome.json",
    "biome.jsonc",
  },
}

local function find_closest_config_file(config_names, current_file)
  if config_names == nil then
    return nil
  end
  for _, config_name in ipairs(config_names) do
    local found = vim.fs.find(config_name, { upward = true, path = vim.fn.fnamemodify(current_file, ":p:h") })
    if #found > 0 then
      return found[1] -- Return the closest config file found
    end
  end
  return nil -- No config file found
end

-- remove wrap and spell autocmd
vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

vim.api.nvim_create_user_command("Format", function()
  local conform = require("conform")
  local formatters = conform.list_formatters(0)
  local current_file = vim.api.nvim_buf_get_name(0)

  if #formatters == 0 then
    vim.notify("Formatted with lsp", vim.log.levels.WARN)
    conform.format({ async = false, lsp_format = "fallback" })
    return
  end

  local formatter_to_use = nil
  for _, formatter in ipairs(formatters) do
    local config_file = find_closest_config_file(formatter_data[formatter.name], current_file)
    if config_file then
      formatter_to_use = formatter.name
      break
    end
  end

  if not formatter_to_use then
    formatter_to_use = formatters[1].name -- Fallback to the first available formatter
  end

  vim.notify("Formatted with " .. formatter_to_use, vim.log.levels.INFO)
  conform.format({ async = false, lsp_format = "never", formatters = { formatter_to_use } })
end, {})

vim.api.nvim_create_user_command("FormatWithLsp", function()
  vim.notify("Formatted with lsp", vim.log.levels.INFO)
  require("conform").format({ async = false, lsp_format = "prefer" })
end, {})

vim.api.nvim_create_user_command("FormatWithBiome", function()
  local conform = require("conform")
  local formatters = conform.list_all_formatters()
  local prevBiomeCondition = nil
  for _, formatter in ipairs(formatters) do
    local is_biome = formatter.name == "biome"
    if is_biome then
      prevBiomeCondition = formatter.available
      break
    end
  end

  if prevBiomeCondition == nil then
    vim.notify("Biome formatter not found", vim.log.levels.WARN)
    return
  end

  if prevBiomeCondition == false then
    conform.formatters.biome.condition = function()
      return true
    end
  end

  vim.notify("Formatted with biome", vim.log.levels.INFO)
  conform.format({ async = false, lsp_format = "never", formatters = { "biome" } })

  if prevBiomeCondition == false then
    -- Reset the condition to the previous state after formatting
    conform.formatters.biome.condition = function()
      return prevBiomeCondition
    end
  end
end, {})

vim.api.nvim_create_user_command("FormatWithPrettier", function()
  local conform = require("conform")
  local formatters = conform.list_all_formatters()
  local prevPrettierCondition = nil
  for _, formatter in ipairs(formatters) do
    local is_prettier = formatter.name == "prettierd"
    if is_prettier then
      prevPrettierCondition = formatter.available
      break
    end
  end

  if prevPrettierCondition == nil then
    vim.notify("Prettierd formatter not found", vim.log.levels.WARN)
    return
  end

  if prevPrettierCondition == false then
    conform.formatters.prettierd.condition = function()
      return true
    end
  end

  vim.notify("Formatted with prettierd", vim.log.levels.INFO)
  conform.format({ async = false, lsp_format = "never", formatters = { "prettierd" } })

  if prevPrettierCondition == false then
    -- Reset the condition to the previous state after formatting
    conform.formatters.prettierd.condition = function()
      return prevPrettierCondition
    end
  end
end, {})

vim.api.nvim_create_user_command("FormatWithOxfmt", function()
  local conform = require("conform")
  local formatters = conform.list_all_formatters()
  local prevOxfmtCondition = nil
  for _, formatter in ipairs(formatters) do
    local is_oxfmt = formatter.name == "oxfmt"
    if is_oxfmt then
      prevOxfmtCondition = formatter.available
      break
    end
  end

  if prevOxfmtCondition == nil then
    vim.notify("Oxfmt formatter not found", vim.log.levels.WARN)
    return
  end

  if prevOxfmtCondition == false then
    conform.formatters.oxfmt.condition = function()
      return true
    end
  end

  vim.notify("Formatted with oxfmt", vim.log.levels.INFO)
  conform.format({ async = false, lsp_format = "never", formatters = { "oxfmt" } })

  if prevOxfmtCondition == false then
    -- Reset the condition to the previous state after formatting
    conform.formatters.oxfmt.condition = function()
      return prevOxfmtCondition
    end
  end
end, {})

-- Auto rename files when moved in oil.nvim
-- https://github.com/folke/snacks.nvim/blob/main/docs/rename.md
vim.api.nvim_create_autocmd("User", {
  pattern = "OilActionsPost",
  callback = function(event)
    if event.data.actions[1].type == "move" then
      Snacks.rename.on_rename_file(event.data.actions[1].src_url, event.data.actions[1].dest_url)
    end
  end,
})

-- Pi.nvim extras config
-- local group = vim.api.nvim_create_augroup("pi-keymaps", { clear = true })
-- local pi = require("pi")
--
-- local function map(buf, key, action, modes)
--   vim.keymap.set(modes or { "n", "i", "v" }, key, action, { buffer = buf })
-- end
--
-- -- Shared across all π windows.
-- vim.api.nvim_create_autocmd("FileType", {
--   group = group,
--   pattern = { "pi-chat-history", "pi-chat-prompt", "pi-chat-attachments" },
--   callback = function(event)
--     map(event.buf, "<C-q>", "<Cmd>PiToggleChat<CR>")
--     map(event.buf, "<M-c>", "<Cmd>PiAbort<CR>")
--   end,
-- })
--
-- -- History window: jump to prompt.
-- vim.api.nvim_create_autocmd("FileType", {
--   group = group,
--   pattern = "pi-chat-history",
--   callback = function(event)
--     map(event.buf, "<S-Down>", pi.focus_chat_prompt)
--   end,
-- })
--
-- -- Prompt window: navigation, scrolling, model & thinking, sessions, attachments.
-- vim.api.nvim_create_autocmd("FileType", {
--   group = group,
--   pattern = "pi-chat-prompt",
--   callback = function(event)
--     -- focus
--     map(event.buf, "<S-Up>", pi.focus_chat_history)
--     map(event.buf, "<S-Down>", pi.focus_chat_attachments)
--     -- scroll history from the prompt
--     map(event.buf, "<C-Up>", function()
--       pi.scroll_chat_history("up", 2)
--     end)
--     map(event.buf, "<C-Down>", function()
--       pi.scroll_chat_history("down", 2)
--     end)
--     -- model & thinking
--     map(event.buf, "<M-m>", pi.cycle_model)
--     map(event.buf, "<M-M>", pi.select_model)
--     map(event.buf, "<M-t>", pi.cycle_thinking_level)
--     map(event.buf, "<M-T>", pi.select_thinking_level)
--     -- sessions & context
--     map(event.buf, "<M-n>", pi.new_session)
--     map(event.buf, "<M-x>", pi.compact)
--     -- attachments
--     map(event.buf, "<C-v>", pi.paste_image)
--   end,
-- })
--
-- -- Attachments window: jump back to prompt, paste image.
-- vim.api.nvim_create_autocmd("FileType", {
--   group = group,
--   pattern = "pi-chat-attachments",
--   callback = function(event)
--     map(event.buf, "<S-Up>", pi.focus_chat_prompt)
--     map(event.buf, "<C-v>", pi.paste_image)
--   end,
-- })
