local prefix = "<Leader>a"

return {
  {
    "zbirenbaum/copilot.lua",
    opts = {
      -- copilot_model = "claude-3.5-sonnet",
      server = {
        type = "binary",
      },
      suggestion = {
        -- debounce for reliable multi-line suggestions
        debounce = 200, -- debounce time in milliseconds
      },
    },
  },

  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    lazy = true,
    version = false, -- Never set this value to "*"! Never!
    opts = {
      mappings = {
        ask = prefix .. "<CR>",
        edit = prefix .. "e",
        refresh = prefix .. "r",
        focus = prefix .. "f",
        toggle = {
          default = prefix .. "t",
          debug = prefix .. "d",
          hint = prefix .. "h",
          suggestion = prefix .. "s",
          repomap = prefix .. "R",
        },
        diff = {
          next = "]c",
          prev = "[c",
        },
        files = {
          add_current = prefix .. ".",
        },
      },
      behaviour = {
        auto_suggestions = false,
      },
      provider = "copilot",
      providers = {
        copilot = {
          model = "claude-sonnet-4",
          extra_request_body = {
            temperature = 0,
            max_tokens = 8192,
          },
        },
      },
      selector = {
        provider = "snacks",
      },
      input = {
        provider = "snacks",
        provider_opts = {
          title = "Avante Input",
          icon = " ",
        },
      },
      hints = {
        enabled = false,
      },
    },
    -- if you want to build from source then do `make BUILD_FROM_SOURCE=true`
    -- dynamically build it, taken from astronvim
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "folke/snacks.nvim",
      "zbirenbaum/copilot.lua",
      "echasnovski/mini.icons",
      -- {
      --   -- support for image pasting
      --   "HakonHarnes/img-clip.nvim",
      --   event = "VeryLazy",
      --   opts = {
      --     -- recommended settings
      --     default = {
      --       embed_image_as_base64 = false,
      --       prompt_for_file_name = false,
      --       drag_and_drop = {
      --         insert_mode = true,
      --       },
      --       -- required for Windows users
      --       use_absolute_path = true,
      --     },
      --   },
      --   keys = {
      --     -- suggested keymap
      --     { "<leader>P", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
      --   },
      -- },
      {
        -- Make sure to set this up properly if you have lazy=true
        "MeanderingProgrammer/render-markdown.nvim",
        dependencies = {
          -- make sure rendering happens even without opening a markdown file first
          "yetone/avante.nvim",
        },
        opts = function(_, opts)
          opts.file_types = opts.file_types or { "markdown", "norg", "rmd", "org" }
          vim.list_extend(opts.file_types, { "Avante" })
        end,
      },
    },
  },
}
