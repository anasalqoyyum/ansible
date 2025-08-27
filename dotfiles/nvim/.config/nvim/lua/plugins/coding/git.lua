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
    },
  },
}
