---@alias ConformCtx {buf: number, filename: string, dirname: string}
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

-- https://biomejs.dev/internals/language-support/
local biomeSupported = {
  -- "astro",
  "css",
  "graphql",
  -- "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  -- "markdown",
  -- "svelte",
  "typescript",
  "typescriptreact",
  -- "vue",
  -- "yaml",
}

--- Checks if a Prettier config file exists for the given context
---@param ctx ConformCtx
function M.has_config(ctx)
  vim.fn.system({ "prettier", "--find-config-path", ctx.filename })
  return vim.v.shell_error == 0
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

M.has_config = LazyVim.memoize(M.has_config)
M.has_parser = LazyVim.memoize(M.has_parser)
M.biome_support = LazyVim.memoize(M.biome_support)

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "prettierd", "prettier", "biome" } },
  },

  -- conform
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

      opts.formatters = opts.formatters or {}
      opts.formatters.prettierd = {
        condition = function(_, ctx)
          return M.has_parser(ctx)
            and (vim.g.lazyvim_prettier_needs_config ~= true or M.has_config(ctx) or not M.biome_support(ctx))
        end,
      }
      opts.formatters.biome = {
        condition = function(_, ctx)
          local prettierd_condition = opts.formatters.prettierd.condition(_, ctx)
          return not prettierd_condition
        end,
      }
    end,
  },

  -- none-ls support
  {
    "nvimtools/none-ls.nvim",
    optional = true,
    opts = function(_, opts)
      local nls = require("null-ls")
      opts.sources = opts.sources or {}
      table.insert(opts.sources, nls.builtins.formatting.prettierd)
      table.insert(opts.sources, nls.builtins.formatting.biome)
    end,
  },

  -- force enable biome in js
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("package.json", ".git", "biome.json", "biome.jsonc")(fname)
          end,
          single_file_support = true,
        },
      },
    },
  },
}
