return {
  -- requires tinymist
  {
    "mason-org/mason.nvim",
    opts = {
      ensure_installed = {
        "tinymist",
        "typstyle",
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "typst" },
    },
  },

  -- add tinymist to lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "mason.nvim",
      "mason-org/mason-lspconfig.nvim",
    },
    ---@class PluginLspOpts
    opts = {
      ---@type lspconfig.options
      servers = {
        tinymist = {
          keys = {
            {
              "<leader>cP",
              function()
                local buf_name = vim.api.nvim_buf_get_name(0)
                local file_name = vim.fn.fnamemodify(buf_name, ":t")
                LazyVim.lsp.execute({
                  command = "tinymist.pinMain",
                  arguments = { buf_name },
                })
                LazyVim.info("Tinymist: Pinned " .. file_name)
              end,
              desc = "Pin main file",
            },
          },
          workspace_required = false,
          --- See [Tinymist Server Configuration](https://github.com/Myriad-Dreamin/tinymist/blob/main/Configuration.md) for references.
          settings = {
            formatterMode = "typstyle",
            -- exportPdf = "onType", -- disable for now due to weirdness with module
            -- semanticTokens = "disable", -- disable for now due to lazyvim not using it
          },
        },
      },
    },
  },

  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        typst = { "typstyle", lsp_format = "prefer" },
      },
    },
  },

  {
    "chomosuke/typst-preview.nvim",
    cmd = { "TypstPreview", "TypstPreviewToggle", "TypstPreviewUpdate" },
    keys = {
      {
        "<leader>cp",
        ft = "typst",
        "<cmd>TypstPreviewToggle<cr>",
        desc = "Toggle Typst Preview",
      },
    },
    opts = {
      dependencies_bin = {
        tinymist = "tinymist",
      },
    },
  },

  {
    "folke/ts-comments.nvim",
    opts = {
      lang = {
        typst = { "// %s", "/* %s */" },
      },
    },
  },
}
