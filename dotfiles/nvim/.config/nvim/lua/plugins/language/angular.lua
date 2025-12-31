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
          Snacks.util.lsp.on({ name = "angularls" }, function(_, client)
            --HACK: disable angular renaming capability due to duplicate rename popping up
            client.server_capabilities.renameProvider = false
          end)
        end,
      },
    },
  },
}
