return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "vue", "css" } },
  },

  -- Add LSP servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vue_ls = {},
        vtsls = {},
      },
    },
  },

  -- Configure tsserver plugin
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      table.insert(opts.servers.vtsls.filetypes, "vue")
      LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
        {
          name = "@vue/typescript-plugin",
          location = LazyVim.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
          languages = { "vue" },
          configNamespace = "typescript",
          enableForWorkspaceTypeScriptVersions = true,
        },
      })

      -- table.insert(opts.servers.ts_ls.filetypes, "vue")
      -- LazyVim.extend(opts.servers.ts_ls, "init_options.plugins", {
      --   {
      --     name = "@vue/typescript-plugin",
      --     location = LazyVim.get_pkg_path("vue-language-server", "/node_modules/@vue/language-server"),
      --     languages = { "vue" },
      --     configNamespace = "typescript",
      --     enableForWorkspaceTypeScriptVersions = true,
      --   },
      -- })
    end,
  },
}
