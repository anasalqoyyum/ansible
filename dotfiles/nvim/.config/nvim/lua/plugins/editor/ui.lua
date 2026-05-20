-- Declare a global function to retrieve the current directory
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    -- If there is no current directory (e.g. over ssh), just show the buffer name
    return vim.api.nvim_buf_get_name(0)
  end
end

local function to_present_git(word)
  if word == "added" then
    return "Add"
  end

  if word == "changed" then
    return "Change"
  end

  if word == "removed" then
    return "Delete"
  end

  return word
end

return {
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    opts = {
      presets = {
        lsp_doc_border = true,
      },
      lsp = {
        hover = {
          enabled = true,
          silent = true,
        },
        signature = {
          enabled = false, -- using blinkcmp signatures
        },
        documentation = {
          opts = {
            scrollbar = true,
          },
        },
      },
    },
  },

  {
    "mistweaverco/bafa.nvim",
    event = "VeryLazy",
    opts = {
      ui = {
        title = {
          text = "",
        },
        icons = {
          diagnostics = {
            Error = "E ",
            Warn = "W ",
            Info = "H ",
            Hint = "I ",
          },
        },
      },
    },
    keys = {
      {
        "<leader>bb",
        function()
          require("bafa.ui").toggle()
        end,
        desc = "Toggle Buffer List",
      },
    },
  },

  -- add statusline/filename in top right
  {
    "b0o/incline.nvim",
    event = "VeryLazy",
    config = function()
      local devicons = require("nvim-web-devicons")
      require("incline").setup({
        render = function(props)
          local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(props.buf), ":t")
          if filename == "" then
            filename = "[No Name]"
          end
          local ft_icon, ft_color = devicons.get_icon_color(filename)

          local function get_git_diff()
            local icons = { removed = " ", changed = " ", added = " " }
            local signs = vim.b[props.buf].gitsigns_status_dict
            local labels = {}
            if signs == nil then
              return labels
            end
            for name, icon in pairs(icons) do
              if tonumber(signs[name]) and signs[name] > 0 then
                table.insert(labels, { icon .. signs[name] .. " ", group = "GitSigns" .. to_present_git(name) })
              end
            end
            if #labels > 0 then
              -- table.insert(labels, { "┊ " })
              table.insert(labels, { "| " })
            end
            return labels
          end

          local modified = vim.bo[props.buf].modified and "●"
          return {
            { get_git_diff() },
            { (ft_icon or "") .. " ", guifg = ft_color, guibg = "none" },
            {
              filename .. " ",
              gui = vim.bo[props.buf].modified and "bold,italic" or "bold",
              group = vim.bo[props.buf].modified and "MatchParen" or "",
            },
            { modified or "", gui = "bold", group = "MatchParen" },
          }
        end,
        window = {
          zindex = 25,
        },
      })
    end,
  },

  -- Oil and related plugins
  {
    "stevearc/oil.nvim",
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      -- win_options = {
      --   winbar = "%!v:lua.get_oil_winbar()",
      -- },
      keymaps = {
        ["<C-s>"] = false,
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["<C-r>"] = "actions.refresh",
        ["q"] = { "actions.close", mode = "n" },
      },
      -- give me back the rounded borders
      float = { border = "rounded" },
      confirmation = { border = "rounded" },
      progress = { border = "rounded" },
      ssh = { border = "rounded" },
      keymaps_help = { border = "rounded" },
    },
    keys = {
      {
        "-",
        "<cmd>Oil --float<cr>",
        desc = "Open parent directory",
      },
    },
  },

  {
    "saghen/blink.indent",
    enabled = vim.g.use_blink_indent,
    --- @module 'blink.indent'
    --- @type blink.indent.Config
    opts = {
      static = {
        char = "│",
        highlights = { "BlinkIndent" },
      },
      scope = {
        char = "│",
        highlights = { "BlinkIndentScope" },
      },
    },
  },

  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      indent = { enabled = not vim.g.use_blink_indent },
      words = { enabled = false },
      notifier = { enabled = false },
      rename = { enabled = true },
      explorer = {
        replace_netrw = false,
      },
      picker = {
        layout = "telescope_small",
        layouts = {
          select_reverse = {
            reverse = true,
            -- hidden = { "preview" },
            layout = {
              backdrop = false,
              width = 0.5,
              min_width = 80,
              height = 0.5,
              min_height = 3,
              box = "vertical",
              border = "rounded",
              title = "{title} {live} {flags}",
              title_pos = "center",
              { win = "preview", title = "{preview}", height = 0.4, border = "bottom" },
              { win = "list", border = "none" },
              { win = "input", height = 1, border = "top" },
            },
          },
          telescope_small = {
            reverse = true,
            layout = {
              box = "horizontal",
              backdrop = false,
              width = 0.5,
              height = 0.5,
              border = "rounded",
              {
                box = "vertical",
                { win = "list", border = "none" },
                { win = "input", height = 1, border = "top", title = "{title} {live} {flags}", title_pos = "center" },
              },
              {
                win = "preview",
                title = "{preview}",
                width = 0.45,
                border = "left",
                title_pos = "center",
              },
            },
          },
        },
        sources = {
          explorer = {
            layout = { layout = { position = "right" } },
            auto_close = true,
            actions = {
              safe_delete = function(picker)
                local selected = picker:selected({ fallback = true })
                local is_root = vim.iter(selected):any(function(s)
                  return not s.parent
                end)
                if is_root then
                  vim.notify("No, bad boy!")
                  return
                end
                picker:action("explorer_del")
              end,
            },
            win = {
              list = {
                keys = {
                  ["d"] = "safe_delete",
                },
              },
            },
          },
        },
        ---@class snacks.picker.formatters.Config
        formatters = {
          file = {
            filename_first = true,
            truncate = 100,
          },
        },
        ---@class snacks.picker.matcher.Config
        matcher = {
          frecency = true,
        },
        win = {
          preview = {
            wo = {
              wrap = true,
            },
          },
          input = {
            keys = {
              ["<C-\\>"] = { "edit_vsplit", mode = { "i", "n" } },
            },
          },
        },
      },
      image = {
        doc = {
          inline = false,
          float = false,
        },
      },
    },
    keys = {
      {
        "<leader>fs",
        function()
          Snacks.picker.smart()
        end,
        desc = "Smart Find Files",
      },
      {
        "<leader>fm",
        function()
          Snacks.picker.buffers({ modified = true })
        end,
        desc = "Modified Buffers",
      },
      -- needed since I disabled notifier.
      {
        "<leader>n",
        "<cmd>Noice pick<cr>",
        desc = "Notification History",
      },
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
        enabled = false,
        preset = {
          header = [[
        ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣬⡛⣿⣿⣿⣯⢻
        ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡟⢻⣿⣿⢟⣻⣿⣿⣿⣿⣿⣿⣮⡻⣿⣿⣧
        ⣿⣿⣿⣿⣿⢻⣿⣿⣿⣿⣿⣿⣆⠻⡫⣢⠿⣿⣿⣿⣿⣿⣿⣿⣷⣜⢻⣿
        ⣿⣿⡏⣿⣿⣨⣝⠿⣿⣿⣿⣿⣿⢕⠸⣛⣩⣥⣄⣩⢝⣛⡿⠿⣿⣿⣆⢝
        ⣿⣿⢡⣸⣿⣏⣿⣿⣶⣯⣙⠫⢺⣿⣷⡈⣿⣿⣿⣿⡿⠿⢿⣟⣒⣋⣙⠊
        ⣿⡏⡿⣛⣍⢿⣮⣿⣿⣿⣿⣿⣿⣿⣶⣶⣶⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿
        ⣿⢱⣾⣿⣿⣿⣝⡮⡻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠛⣋⣻⣿⣿⣿⣿
        ⢿⢸⣿⣿⣿⣿⣿⣿⣷⣽⣿⣿⣿⣿⣿⣿⣿⡕⣡⣴⣶⣿⣿⣿⡟⣿⣿⣿
        ⣦⡸⣿⣿⣿⣿⣿⣿⡛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡇⣿⣿⣿
        ⢛⠷⡹⣿⠋⣉⣠⣤⣶⣶⣿⣿⣿⣿⣿⣿⡿⠿⢿⣿⣿⣿⣿⣿⣷⢹⣿⣿
        ⣷⡝⣿⡞⣿⣿⣿⣿⣿⣿⣿⣿⡟⠋⠁⣠⣤⣤⣦⣽⣿⣿⣿⡿⠋⠘⣿⣿
        ⣿⣿⡹⣿⡼⣿⣿⣿⣿⣿⣿⣿⣧⡰⣿⣿⣿⣿⣿⣹⡿⠟⠉⡀⠄⠄⢿⣿
        ⣿⣿⣿⣽⣿⣼⣛⠿⠿⣿⣿⣿⣿⣿⣯⣿⠿⢟⣻⡽⢚⣤⡞⠄⠄⠄⢸⣿
      ]],
          -- stylua: ignore
          ---@type snacks.dashboard.Item[]
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
            { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
            { icon = " ", key = "g", desc = "Find Text", action = ":lua Snacks.dashboard.pick('live_grep')" },
            { icon = " ", key = "b", desc = "File browser", action = function() require("yazi").yazi(nil,
                vim.fn.getcwd()) end },
            { icon = " ", key = "s", desc = "Restore Session", section = "session" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
        sections = {
          -- { section = "header" },
          { section = "keys", gap = 1, padding = 2 },
          { section = "recent_files", cwd = true, padding = 2 },
          { section = "startup" },
        },
      },
    },
  },

  {
    "folke/trouble.nvim",
    opts = {
      win = {
        size = 0.15,
      },
    },
  },

  {
    "lewis6991/satellite.nvim",
    event = "VeryLazy",
    opts = {},
  },

  {
    "folke/todo-comments.nvim",
    opts = {
      keywords = {
        FIX = {
          icon = "▍ ",
          color = "error",
          alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
        },
        TODO = { icon = "▍ ", color = "info" },
        HACK = { icon = "▍ ", color = "warning" },
        WARN = { icon = "▍ ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = "▍ ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = "▍ ", color = "hint", alt = { "INFO" } },
        TEST = { icon = "▍ ", color = "test", alt = { "TESTING", "PASSED", "FAILED" } },
      },
    },
  },
}
