return {
  { "wuelnerdotexe/vim-astro", event = "VeryLazy", enabled = false },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "astro", "css" } },
  },

  -- LSP Servers
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        astro = {},
      },
    },
  },

  -- Configure tsserver plugin
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      LazyVim.extend(opts.servers.vtsls, "settings.vtsls.tsserver.globalPlugins", {
        {
          name = "@astrojs/ts-plugin",
          location = LazyVim.get_pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin"),
          enableForWorkspaceTypeScriptVersions = true,
        },
      })
      -- LazyVim.extend(opts.servers.ts_ls, "init_options.plugins", {
      --   {
      --     name = "@astrojs/ts-plugin",
      --     location = LazyVim.get_pkg_path("astro-language-server", "/node_modules/@astrojs/ts-plugin"),
      --     enableForWorkspaceTypeScriptVersions = true,
      --   },
      -- })
    end,
  },
}
