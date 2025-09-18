-- somehow always attached to any typescript files
if true then
  return {}
end

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
        angularls = {},
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

  -- Configure tsserver plugin
  -- {
  --   "neovim/nvim-lspconfig",
  --   opts = function(_, opts)
  --     LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
  --       {
  --         name = "@angular/language-server",
  --         location = LazyVim.get_pkg_path("angular-language-server", "/node_modules/@angular/language-server"),
  --         enableForWorkspaceTypeScriptVersions = false,
  --       },
  --     })
  --     LazyVim.extend(opts.servers.ts_ls, "init_options.plugins", {
  --       {
  --         name = "@angular/language-server",
  --         location = LazyVim.get_pkg_path("angular-language-server", "/node_modules/@angular/language-server"),
  --         enableForWorkspaceTypeScriptVersions = false,
  --       },
  --     })
  --   end,
  -- },
}
