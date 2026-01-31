local util = require("lspconfig.util")
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

--[[
Example valid oxlint_settings (assuming defaults, buffer = 12, and git dir = /home/whoami/projects/myapp):

{
  run = "onType",
  enable = true,
  configPath = ".oxlintrc.json",
  workingDirectory = { mode = "location" },
  workspaceFolder = {
    uri = "file:///home/whoami/projects/myapp",
    name = "myapp",
  },
}
]]
local oxlint_settings = {
  run = "onType", -- or "onSave"
  typeAware = true,
  fixKind = "all",
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

-- Override eslint_d parser to handle missing config file error and clean output (e.g when React not in settings)
-- Note: this is needed because eslint_d returns non-zero exit code when config file is missing
-- Might not be needed anymore after: https://github.com/mfussenegger/nvim-lint/pull/851
local eslint_d = require("lint").linters.eslint_d
eslint_d.parser = function(output, bufnr)
  if string.find(output, "Error: Could not find config file") then
    return {}
  end

  local json_start, json_end = output:find("%b[]")
  local clean_output = json_start and output:sub(json_start, json_end) or output

  local result = require("lint.linters.eslint").parser(clean_output, bufnr)
  for _, d in ipairs(result) do
    d.source = "eslint_d"
  end
  return result
end

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "oxlint", "biome", "eslint-lsp", "eslint_d" } },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      opts = {
        -- Event to trigger linters (added TextChanged, so it react after delete and undo in normal mode)
        events = { "BufWritePost", "BufReadPost", "InsertLeave", "TextChanged" },
      },
      linters_by_ft = {
        javascript = { "eslint_d" },
        typescript = { "eslint_d" },
        javascriptreact = { "eslint_d" },
        typescriptreact = { "eslint_d" },
      },
      ---@type table<string,table>
      linters = {
        -- using eslint_d only when eslint config file is present
        eslint_d = {
          condition = function(ctx)
            local config_found = vim.fs.find(eslint_config_files, {
              path = ctx.filename,
              upward = true,
            })[1]
            return vim.g.eslint_flavor == "eslint_d" and config_found ~= nil
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
          root_dir = function(bufnr, on_dir)
            if vim.g.typescript_linter == "biome" then
              return on_dir(force_linter_to_run(bufnr))
            end

            -- The project root is where the LSP can be started from
            -- As stated in the documentation above, this LSP supports monorepos and simple projects.
            -- We select then from the project root, which is identified by the presence of a package
            -- manager lock file.
            local root_markers = {
              "package-lock.json",
              "yarn.lock",
              "pnpm-lock.yaml",
              "bun.lockb",
              "bun.lock",
              "deno.lock",
            }
            -- Give the root markers equal priority by wrapping them in a table
            root_markers = vim.fn.has("nvim-0.11.3") == 1 and { root_markers, { ".git" } }
              or vim.list_extend(root_markers, { ".git" })

            -- We fallback to the current working directory if no project root is found
            local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

            -- We know that the buffer is using Biome if it has a config file
            -- in its directory tree.
            local filename = vim.api.nvim_buf_get_name(bufnr)
            local biome_config_files = { "biome.json", "biome.jsonc" }
            biome_config_files = util.insert_package_json(biome_config_files, "biomejs", filename)
            local is_buffer_using_biome = vim.fs.find(biome_config_files, {
              path = filename,
              type = "file",
              limit = 1,
              upward = true,
              stop = vim.fs.dirname(project_root),
            })[1]
            if not is_buffer_using_biome then
              return
            end

            on_dir(project_root)
          end,
          workspace_required = true,
        },
        oxlint = {
          root_dir = function(bufnr, on_dir)
            if vim.g.typescript_linter == "oxlint" then
              return on_dir(force_linter_to_run(bufnr))
            end

            local fname = vim.api.nvim_buf_get_name(bufnr)
            local root_markers = util.insert_package_json({ ".oxlintrc.json" }, "oxlint", fname)
            on_dir(vim.fs.dirname(vim.fs.find(root_markers, { path = fname, upward = true })[1]))
          end,
          settings = oxlint_settings,
          -- INFO: we need this to make server start with correct params
          -- https://github.com/oxc-project/oxc/tree/main/crates/oxc_language_server#workspace-options
          init_options = {
            settings = oxlint_settings,
          },
          -- set to false to allow linting even without workspace folder (e.g if ran globally)
          workspace_required = true,
        },
        eslint = {
          enabled = vim.g.eslint_flavor == "eslint",
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
