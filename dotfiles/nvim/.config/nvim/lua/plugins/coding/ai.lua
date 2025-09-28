local prefix = "<Leader>a"

return {
  {
    "yetone/avante.nvim",
    enabled = vim.g.ai_chat == "avante" or (vim.g.ai_chat == "opencode" and vim.fn.executable("opencode") == 0),
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
          model = "gpt-5-codex",
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
    "sudo-tee/opencode.nvim",
    enabled = vim.g.ai_chat == "opencode" and vim.fn.executable("opencode") == 1,
    event = "VeryLazy",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = function(_, opts)
          opts.anti_conceal = { enabled = false }
          opts.file_types = opts.file_types or { "markdown", "norg", "rmd", "org" }
          vim.list_extend(opts.file_types, { "opencode_output" })
        end,
        ft = function(_, ft)
          vim.list_extend(ft, { "markdown", "Avante", "copilot-chat", "opencode_output" })
        end,
      },
      "saghen/blink.cmp",
      "folke/snacks.nvim",
    },
    opts = {
      keymap = {
        global = {
          toggle = prefix .. "a", -- Open opencode. Close if opened
          open_input = prefix .. "i", -- Opens and focuses on input window on insert mode
          open_input_new_session = prefix .. "I", -- Opens and focuses on input window on insert mode. Creates a new session
          open_output = prefix .. "o", -- Opens and focuses on output window
          toggle_focus = prefix .. "t", -- Toggle focus between opencode and last window
          close = prefix .. "q", -- Close UI windows
          select_session = prefix .. "s", -- Select and load a opencode session
          configure_provider = prefix .. "p", -- Quick provider and model switch from predefined list
          diff_open = prefix .. "d", -- Opens a diff tab of a modified file since the last opencode prompt
          diff_next = prefix .. "]", -- Navigate to next file diff
          diff_prev = prefix .. "[", -- Navigate to previous file diff
          diff_close = prefix .. "c", -- Close diff view tab and return to normal editing
          diff_revert_all_last_prompt = prefix .. "ra", -- Revert all file changes since the last opencode prompt
          diff_revert_this_last_prompt = prefix .. "rt", -- Revert current file changes since the last opencode prompt
          diff_revert_all = prefix .. "rA", -- Revert all file changes since the last opencode session
          diff_revert_this = prefix .. "rT", -- Revert current file changes since the last opencode session
          swap_position = prefix .. "x", -- Swap Opencode pane left/right
        },
        window = {
          submit = "<cr>", -- Submit prompt (normal mode)
          submit_insert = "<C-s>", -- Submit prompt (insert mode)
          close = "<esc>", -- Close UI windows
          stop = "<C-c>", -- Stop opencode while it is running
          next_message = "]]", -- Navigate to next message in the conversation
          prev_message = "[[", -- Navigate to previous message in the conversation
          mention_file = "@", -- Pick a file and add to context. See File Mentions section
          slash_command = "/", -- Pick a command to run in the input window
          toggle_pane = "<tab>", -- Toggle between input and output panes
          prev_prompt_history = "<up>", -- Navigate to previous prompt in history
          next_prompt_history = "<down>", -- Navigate to next prompt in history
          switch_mode = "<M-m>", -- Switch between modes (build/plan)
          focus_input = "<C-i>", -- Focus on input wirndow and enter insert mode at the end of the input from the output window
          select_child_session = prefix .. "S", -- Select and load a child session
          debug_messages = prefix .. "D", -- Open raw message in new buffer for debugging
          debug_output = prefix .. "O", -- Open raw output in new buffer for debugging
        },
      },
      ui = {
        window_width = 0.30, -- Width as percentage of editor width
      },
    },
  },
}
