return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = {
          spacing = 4,
          source = "if_many",
          prefix = "",
          -- only shows virtual text for the current line
          -- current_line = true,

          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",
          -- prefix = ""
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },

  {
    "rmagatti/goto-preview",
    event = "VeryLazy",
    config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
    opts = {
      default_mappings = true,
      vim_ui_input = false,
      references = {
        provider = "snacks",
      },
    },
  },

  {
    "chrisgrieser/nvim-rulebook",
    enabled = false,
    branch = "dev",
    event = "LspAttach",
    opts = {
      suppressFormatter = {
        javascript = {
          ignoreBlock = "// prettier-ignore",
          location = "prevLine",
        },
      },
    },
    keys = {
      {
        "<leader>ri",
        function()
          require("rulebook").ignoreRule()
        end,
        desc = "Rulebook: Ignore diagnostic rule",
      },
      {
        "<leader>rl",
        function()
          require("rulebook").lookupRule()
        end,
        desc = "Rulebook: Lookup diagnostic rule",
      },
      {
        "<leader>ry",
        function()
          require("rulebook").yankDiagnosticCode()
        end,
        desc = "Rulebook: Yank diagnostic code",
      },
      {
        "<leader>rf",
        function()
          require("rulebook").suppressFormatter()
        end,
        mode = { "n", "x" },
        desc = "Rulebook: Suppress formatter",
      },
    },
  },
}
