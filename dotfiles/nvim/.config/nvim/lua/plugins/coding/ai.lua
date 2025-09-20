local prefix = "<Leader>a"

return {
  {
    "zbirenbaum/copilot.lua",
    dependencies = {
      "copilotlsp-nvim/copilot-lsp", -- (optional) for NES functionality (and still experimental)
      init = function()
        vim.g.copilot_nes_debounce = 500
      end,
    },
    opts = {
      server = {
        type = "binary",
      },
      -- suggestion = {
      --   debounce = 200, -- debounce for reliable multi-line suggestions (in ms)
      -- },
      nes = {
        enabled = false,
        auto_trigger = true,
        keymap = {
          accept_and_goto = "<M-y>",
          accept = false,
          dismiss = "<ESC>",
        },
      },
    },
  },

  {
    "yetone/avante.nvim",
    event = "VeryLazy",
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
      selection = {
        enabled = true,
        hint_display = "none",
      },
      provider = "copilot",
      providers = {
        copilot = {
          model = "gpt-5-mini",
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
      "nvim-mini/mini.icons",
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
    },
  },

  {
    "NickvanDyke/opencode.nvim",
    enabled = vim.fn.executable("opencode") == 1,
    lazy = true,
    dependencies = {
      { "folke/snacks.nvim", opts = { input = { enabled = true } } },
    },
    ---@type opencode.Opts
    opts = {
      -- Your configuration, if any — see lua/opencode/config.lua
    },
    -- stylua: ignore start
    keys = {
      { '<leader>aoA', function() require('opencode').ask() end,                                     desc = 'Ask opencode', },
      { '<leader>aoa', function() require('opencode').ask('@cursor: ') end,                          desc = 'Ask opencode about this',      mode = 'n', },
      { '<leader>aoa', function() require('opencode').ask('@selection: ') end,                       desc = 'Ask opencode about selection', mode = 'v', },
      { '<leader>aot', function() require('opencode').toggle() end,                                  desc = 'Toggle embedded opencode', },
      { '<leader>aon', function() require('opencode').command('session_new') end,                    desc = 'New session', },
      { '<leader>aoy', function() require('opencode').command('messages_copy') end,                  desc = 'Copy last message', },
      { '<S-C-u>',     function() require('opencode').command('messages_half_page_up') end,          desc = 'Scroll messages up', },
      { '<S-C-d>',     function() require('opencode').command('messages_half_page_down') end,        desc = 'Scroll messages down', },
      { '<leader>aop', function() require('opencode').select_prompt() end,                           desc = 'Select prompt',                mode = { 'n', 'v', }, },
      -- Example: keymap for custom prompt
      { '<leader>aoe', function() require('opencode').prompt("Explain @cursor and its context") end, desc = "Explain code near cursor", },
    },
    -- stylua: ignore end
  },
}
