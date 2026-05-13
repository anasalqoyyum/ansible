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
    -- "sindrets/diffview.nvim",
    -- NOTE: this is a fork of original but more maintained
    "dlyongemallo/diffview.nvim",
    event = "VeryLazy",
    opts = {
      show_help_hints = false,
      hide_merge_artifacts = true,
      clean_up_buffers = true,
      auto_close_on_empty = true,
      enhanced_diff_hl = true,
      use_icons = true,
      view = {
        default = {
          winbar_info = false,
          disable_diagnostics = true,
        },
        file_history = {
          layout = "diff2_vertical",
        },
        merge_tool = {
          layout = "diff4_mixed",
          winbar_info = true,
        },
        cycle_layouts = {
          merge_tool = { "diff4_mixed", "diff3_mixed", "diff3_horizontal", "diff1_plain" },
        },
      },
      file_panel = {
        show_branch_name = true,
        always_show_sections = true,
        win_config = {
          position = "right",
        },
      },
      file_history_panel = {
        stat_style = "both",
        date_format = "relative",
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
}
