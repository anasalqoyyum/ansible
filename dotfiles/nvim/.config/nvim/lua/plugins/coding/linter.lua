-- local util = require("lspconfig.util")
-- local auto_format = vim.g.lazyvim_eslint_auto_format == nil or vim.g.lazyvim_eslint_auto_format

-- sync this with oxlint or biome from nvim-lspconfig due to I need to force run oxlint or biome
-- ref: https://github.com/neovim/nvim-lspconfig/blob/master/lsp/biome.lua
local function force_linter_to_run(bufnr)
  -- The project root is where the LSP can be started from
  -- As stated in the documentation above, this LSP supports monorepos and simple projects.
  -- We select then from the project root, which is identified by the presence of a package
  -- manager lock file.
  local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
  -- Give the root markers equal priority by wrapping them in a table
  root_markers = { root_markers, { ".git" } }
  -- We fallback to the current working directory if no project root is found
  local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

  return project_root
end

local oxlint_settings = {
  run = "onType", -- or "onSave"
  typeAware = true,
}

local eslint_config_files = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
}

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "oxlint", "biome", "eslint-lsp", "eslint_d" } },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
      },
      linters = {
        -- using eslint_d only when eslint config file is present
        eslint_d = {
          condition = function(ctx)
            return vim.fs.find(eslint_config_files, {
              path = ctx.filename,
              upward = true,
            })[1]
          end,
        },
      },
    },
  },

  -- enable either biome or oxlint linter
  -- root_dir shenanigans is needed so it can attach without root markers and config
  {
    "neovim/nvim-lspconfig",
    opts = {
      ---@type vim.lsp.Config
      servers = {
        biome = {
          enabled = vim.g.typescript_linter == "biome",
          root_dir = function(bufnr, on_dir)
            -- NOTE: WE DON'T CARE about this since we need biome to lint without config (and biome can resolve it by itself)
            -- We know that the buffer is using Biome if it has a config file
            -- in its directory tree.
            -- local filename = vim.api.nvim_buf_get_name(bufnr)
            -- local biome_config_files = { "biome.json", "biome.jsonc" }
            -- biome_config_files = util.insert_package_json(biome_config_files, "biome", filename)
            -- local is_buffer_using_biome = vim.fs.find(biome_config_files, {
            --   path = filename,
            --   type = "file",
            --   limit = 1,
            --   upward = true,
            --   stop = vim.fs.dirname(project_root),
            -- })[1]
            -- if not is_buffer_using_biome then
            --   return
            -- end

            on_dir(force_linter_to_run(bufnr))
          end,
          workspace_required = false,
        },
        oxlint = {
          enabled = vim.g.typescript_linter == "oxlint",
          root_dir = function(bufnr, on_dir)
            -- NOTE: WE ALSO DON'T CARE about this since we need oxlint to lint without config
            -- local fname = vim.api.nvim_buf_get_name(bufnr)
            -- local root_markers = util.insert_package_json({ ".oxlintrc.json" }, "oxlint", fname)
            -- on_dir(vim.fs.dirname(vim.fs.find(root_markers, { path = fname, upward = true })[1]))

            on_dir(force_linter_to_run(bufnr))
          end,
          settings = oxlint_settings,
          -- INFO: we need this to make server start with correct params
          -- https://github.com/oxc-project/oxc/blob/main/crates/oxc_language_server/src/main.rs#L89-L95
          init_options = {
            settings = oxlint_settings,
          },
          workspace_required = false,
        },
        eslint = {
          settings = {
            -- helps eslint find the eslintrc when it's placed in a subfolder instead of the cwd root
            workingDirectories = { mode = "auto" },
            -- in default lazyvim there's autoformat setup, but we prefer prettierd or biome
            format = false,
          },
        },
      },
    },
  },
}
