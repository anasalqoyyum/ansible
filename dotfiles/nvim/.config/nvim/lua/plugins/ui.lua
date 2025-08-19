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
    "mikavilpas/yazi.nvim",
    lazy = true, -- use `event = "VeryLazy"` for netrw replacement
    keys = {
      {
        "<leader>fy",
        "<cmd>Yazi<cr>",
        desc = "Open Yazi (file manager)",
      },
    },
    opts = {},
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
            { filename .. " ", gui = vim.bo[props.buf].modified and "bold,italic" or "bold" },
            { modified or "", gui = "bold" },
          }
        end,
      })
    end,
  },

  {
    "Bekaboo/dropbar.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local dropbar_api = require("dropbar.api")
      vim.api.nvim_set_hl(0, "WinBar", { bg = "NONE" }) -- no background for dropbar
      vim.keymap.set("n", "<Leader>s;", dropbar_api.pick, { desc = "Pick LSP Symbols" })
      vim.keymap.set("n", "[;", dropbar_api.goto_context_start, { desc = "Go to start of current context" })
      vim.keymap.set("n", "];", dropbar_api.select_next_context, { desc = "Select next context" })
    end,
  },

  -- Oil and related plugins
  {
    "stevearc/oil.nvim",
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      default_file_explorer = true,
      view_options = {
        show_hidden = true,
      },
      win_options = {
        winbar = "%!v:lua.get_oil_winbar()",
      },
      keymaps = {
        ["<C-s>"] = false,
        ["<C-v>"] = { "actions.select", opts = { vertical = true } },
        ["q"] = { "actions.close", mode = "n" },
      },
    },
    -- Optional dependencies
    dependencies = { { "echasnovski/mini.icons", opts = {} } },
    -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
    lazy = false,
  },
  -- most of these plugins slow down oil.nvim on big repo, so we disable them for now
  -- {
  --   "benomahony/oil-git.nvim",
  --   dependencies = { "stevearc/oil.nvim" },
  -- },
  -- {
  --   "JezerM/oil-lsp-diagnostics.nvim",
  --   dependencies = { "stevearc/oil.nvim" },
  --   opts = {},
  -- },

  {
    "folke/snacks.nvim",
    ---@type snacks.Config
    opts = {
      explorer = {
        replace_netrw = false,
      },
      picker = {
        sources = {
          explorer = {
            layout = { layout = { position = "right" } },
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
          input = {
            keys = {
              ["_"] = { "edit_split", mode = { "i", "n" } },
              ["|"] = { "edit_vsplit", mode = { "i", "n" } },
            },
          },
        },
      },
      image = {
        enabled = true,
        doc = {
          enabled = true,
          inline = false,
          float = true,
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
    },
  },

  {
    "folke/snacks.nvim",
    opts = {
      dashboard = {
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
            { icon = " ", key = "b", desc = "File browser", action = function()  require("yazi").yazi(nil, vim.fn.getcwd()) end},
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
    "echasnovski/mini.icons",
    opts = {
      lsp = {
        -- support blink cmp
        copilot = { glyph = "", hl = "MiniIconsRed" },
      },
    },
  },

  -- {
  --   "ibhagwan/fzf-lua",
  --   opts = {
  --     files = {
  --       file_icons = "mini",
  --     },
  --   },
  -- },
}
