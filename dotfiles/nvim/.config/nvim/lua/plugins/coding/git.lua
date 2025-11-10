return {
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame_opts = {
        delay = 0,
      },
    },
  },

  {
    "sindrets/diffview.nvim",
    event = "VeryLazy",
    opts = {
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        default = {
          winbar_info = false,
          disable_diagnostics = true,
        },
        merge_tool = {
          layout = "diff3_mixed",
        },
      },
      file_panel = {
        win_config = {
          position = "right",
        },
      },
      hooks = {
        diff_buf_win_enter = function(bufnr, winid, _)
          -- Turn off cursor line for diffview windows because of BG conflict
          -- setting gross underline:
          -- https://github.com/neovim/neovim/issues/9800
          vim.wo[winid].culopt = "number"

          -- turn off gitsigns inline diff
          ---@diagnostic disable-next-line: param-type-mismatch
          pcall(vim.cmd, "Gitsigns toggle_linehl false")
          ---@diagnostic disable-next-line: param-type-mismatch
          pcall(vim.cmd, "Gitsigns toggle_word_diff false")

          -- clear highlights
          vim.cmd("nohl")

          -- set wrap
          vim.wo[winid].wrap = true

          -- HACK: turn off inlay hints, but diffview is triggering the lsp
          -- to renable them even if they were off (re-editing the buffer?)
          -- add a 100ms delay to make sure they're off. gross.
          vim.defer_fn(function()
            local wins = vim.api.nvim_tabpage_list_wins(0)
            for _, win in ipairs(wins) do
              local buf = vim.api.nvim_win_get_buf(win)
              vim.lsp.inlay_hint.enable(false, { bufnr = buf })
            end
          end, 500)
        end,

        -- disable ts context while in diffview
        view_enter = function(_)
          local ok, ts_context = pcall(require, "treesitter-context")
          if ok and ts_context then
            ts_context.disable()
          end
        end,
        view_leave = function(_)
          local ok, ts_context = pcall(require, "treesitter-context")
          if ok and ts_context then
            ts_context.enable()
          end
        end,
      },
    },
  },

  { "akinsho/git-conflict.nvim", opts = {} },
}
