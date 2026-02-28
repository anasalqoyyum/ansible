local M = {}

local prettierSupported = {
  "astro",
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

-- Should be similar to prettier supported filetypes but oxfmt does not support astro (due to plugin not supported yet)
-- https://oxc.rs/docs/guide/usage/formatter.html#supported-languages
local oxfmtSupported = {
  -- "astro",
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "toml",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}

-- https://biomejs.dev/internals/language-support/
local biomeSupported = {
  "astro",
  "css",
  "graphql",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  -- "markdown",
  "svelte",
  "typescript",
  "typescriptreact",
  "vue",
  -- "yaml",
}

--- Checks if a Prettier config file exists for the given context
---@param ctx ConformCtx
function M.has_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
  return vim.v.shell_error == 0
end

function M.oxfmt_has_config(ctx)
  local config_found = vim.fs.find(".oxfmtrc.json", {
    path = ctx.filename,
    upward = true,
  })[1]
  return config_found ~= nil
end

--- Checks if a parser can be inferred for the given context:
--- * If the filetype is in the supported list, return true
--- * Otherwise, check if a parser can be inferred
---@param ctx ConformCtx
function M.has_parser(ctx)
  local ft = vim.bo[ctx.buf].filetype --[[@as string]]
  -- default filetypes are always supported
  if vim.tbl_contains(prettierSupported, ft) then
    return true
  end
  -- otherwise, check if a parser can be inferred
  local ret = vim.fn.system({ "prettier", "--file-info", ctx.filename })
  ---@type boolean, string?
  local ok, parser = pcall(function()
    return vim.fn.json_decode(ret).inferredParser
  end)
  return ok and parser and parser ~= vim.NIL
end

--- Checks if the current buffer is supported by biome
---@param ctx ConformCtx
function M.biome_support(ctx)
  local ft = vim.bo[ctx.buf].filetype --[[@as string]]
  if vim.tbl_contains(biomeSupported, ft) then
    return true
  else
    return false
  end
end

function M.oxfmt_support(ctx)
  local ft = vim.bo[ctx.buf].filetype --[[@as string]]
  if vim.tbl_contains(oxfmtSupported, ft) then
    return true
  else
    return false
  end
end

M.has_config = LazyVim.memoize(M.has_config)
M.has_parser = LazyVim.memoize(M.has_parser)
M.biome_support = LazyVim.memoize(M.biome_support)
M.oxfmt_support = LazyVim.memoize(M.oxfmt_support)

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "prettierd", "prettier", "biome", "oxfmt" } },
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    ---@class opts ConformOpts
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      for _, ft in ipairs(prettierSupported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "prettierd")
      end
      for _, ft in ipairs(biomeSupported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "biome")
      end
      for _, ft in ipairs(oxfmtSupported) do
        opts.formatters_by_ft[ft] = opts.formatters_by_ft[ft] or {}
        table.insert(opts.formatters_by_ft[ft], "oxfmt")
      end

      opts.formatters = opts.formatters or {}
      -- pretty much prefer prettierd over prettier (faster)
      opts.formatters.prettier = {
        condition = function(_, _)
          return false
        end,
      }
      opts.formatters.prettierd = {
        condition = function(_, ctx)
          return M.has_parser(ctx) and (vim.g.lazyvim_prettier_needs_config ~= true or M.has_config(ctx))
        end,
      }
      opts.formatters.oxfmt = {
        condition = function(_, ctx)
          local prettierd_condition = opts.formatters.prettierd.condition(_, ctx)
          return M.oxfmt_support(ctx) and not prettierd_condition and M.oxfmt_has_config(ctx)
        end,
      }
      opts.formatters.biome = {
        condition = function(_, ctx)
          local prettierd_condition = opts.formatters.prettierd.condition(_, ctx)
          local oxfmt_condition = opts.formatters.oxfmt.condition(_, ctx)
          return not prettierd_condition and not oxfmt_condition and M.biome_support(ctx)
        end,
      }
    end,
  },
}
