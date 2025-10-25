local tiny_inline_diagnostic_disabled = false

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        underline = true,
        update_in_insert = false,
        -- check if tiny-inline-diagnostic is enabled (since that thing is disabling virtual_text)
        virtual_text = {
          spacing = 4,
          prefix = "•",
          source = true,

          -- only shows source if there are multiple sources
          -- source = "if_many",

          -- only shows virtual text for the current line
          -- current_line = true,

          -- only show virtual text above a certain severity
          -- severity = { min = vim.diagnostic.severity.WARN },

          -- this will set set the prefix to a function that returns the diagnostics icon based on the severity
          -- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
          -- prefix = "icons",

          -- Square
          -- prefix = "",

          -- Circle bigger
          -- prefix = ""
        },
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = "▍",
            [vim.diagnostic.severity.WARN] = "▍",
            [vim.diagnostic.severity.HINT] = "▍",
            [vim.diagnostic.severity.INFO] = "▍",
            --     [vim.diagnostic.severity.ERROR] = " ",
            --     [vim.diagnostic.severity.WARN] = " ",
            --     [vim.diagnostic.severity.HINT] = " ",
            --     [vim.diagnostic.severity.INFO] = " ",
          },
        },
        float = {
          border = "rounded",
        },
      },
      inlay_hints = {
        enabled = false,
      },
    },
  },

  -- multi-line inline diagnostics is pretty neat (for JS with multiple linters)
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    enabled = not vim.g.use_builtin_lsp_diagnostics,
    event = "VeryLazy",
    priority = 1000,
    config = function()
      require("tiny-inline-diagnostic").setup({
        preset = "simple",
        transparent_bg = false,
        transparent_cursorline = true,

        options = {
          show_source = {
            enabled = true, -- Enable showing source names
            if_many = false, -- Only show source if multiple sources exist for the same diagnostic
          },
          multilines = {
            enabled = true, -- Enable support for multiline diagnostic messages
            always_show = true, -- Always show messages on all lines of multiline diagnostics
            trim_whitespaces = false, -- Remove leading/trailing whitespace from each line
            tabstop = 4, -- Number of spaces per tab when expanding tabs
          },
          show_related = {
            enabled = true, -- Enable displaying related diagnostics
            max_count = 3, -- Maximum number of related diagnostics to show per diagnostic
          },
          override_open_float = true, -- Automatically disable diagnostics when opening diagnostic float windows (somehow doesn't work?)
        },

        -- signs and blends both replace preset settings
        signs = {
          left = "",
          right = "",
          diag = "•",
          arrow = "    ",
          up_arrow = "    ",
          vertical = " │",
          vertical_end = " └",
        },
        blend = {
          factor = 0.1, -- similar to lsp-builtin virtual_text color bg
        },
      })

      vim.diagnostic.config({ virtual_text = false }) -- Disable Neovim's default virtual text diagnostics
      vim.api.nvim_create_autocmd("User", {
        pattern = "SidekickNesHide",
        callback = function()
          if tiny_inline_diagnostic_disabled then
            tiny_inline_diagnostic_disabled = false
            require("tiny-inline-diagnostic").enable()
          end
        end,
      })
      vim.api.nvim_create_autocmd("User", {
        pattern = "SidekickNesShow",
        callback = function()
          tiny_inline_diagnostic_disabled = true
          require("tiny-inline-diagnostic").disable()
        end,
      })
    end,
    keys = {
      {
        "<leader>uW",
        function()
          require("tiny-inline-diagnostic").toggle()
        end,
        desc = "Toggle Inline Diagnostics",
        mode = "n",
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
