local util = require("lspconfig.util")

return {
  {
    "nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "angular", "scss" })
      end
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
        pattern = { "*.component.html", "*.container.html" },
        callback = function()
          vim.treesitter.start(nil, "angular")
        end,
      })
    end,
  },

  -- LSP Servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        angularls = {
          root_dir = function(bufnr, on_dir)
            local root_markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
            -- Give the root markers equal priority by wrapping them in a table
            root_markers = { root_markers, { ".git" } }
            -- We fallback to the current working directory if no project root is found
            local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

            -- We know that the buffer is using Angular if it has a config file
            -- in its directory tree.
            local filename = vim.api.nvim_buf_get_name(bufnr)
            local angular_config_files = { "angular.json", "nx.json" }
            angular_config_files = util.insert_package_json(angular_config_files, "@angular/core", filename)
            local is_buffer_using_angular = vim.fs.find(angular_config_files, {
              path = filename,
              type = "file",
              limit = 1,
              upward = true,
              stop = vim.fs.dirname(project_root),
            })[1]
            if not is_buffer_using_angular then
              return
            end

            on_dir(project_root)
          end,
        },
        vtsls = {},
      },
      setup = {
        angularls = function()
          LazyVim.lsp.on_attach(function(client)
            --HACK: disable angular renaming capability due to duplicate rename popping up
            client.server_capabilities.renameProvider = false
          end, "angularls")
        end,
      },
    },
  },
}
