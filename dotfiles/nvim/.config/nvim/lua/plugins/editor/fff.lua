return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    opts = {
      prompt = " ",
      title = "Files",
      layout = {
        height = 0.5,
        width = 0.5,
        prompt_position = "bottom", -- or 'top'
        preview_position = "top", -- or 'left', 'right', 'top', 'bottom'
        preview_size = 0.4,
      },
      preview = {
        line_numbers = true,
      },
      keymaps = {
        select_split = "<C-s>",
        select_vsplit = "<C-v>, <C-\\>",
      },
    },
    lazy = false,
    keys = {
      {
        "ff", -- try it if you didn't it is a banger keybinding for a picker
        function()
          require("fff").find_files()
        end,
        desc = "FFFind files",
      },
      {
        "fg",
        function()
          require("fff").live_grep()
        end,
        desc = "LiFFFe grep",
      },
      {
        "fz",
        function()
          require("fff").live_grep({
            grep = {
              modes = { "fuzzy" },
            },
          })
        end,
        desc = "Live fffuzy grep",
      },
      {
        "fc",
        function()
          require("fff").live_grep({ query = vim.fn.expand("<cword>") })
        end,
        desc = "Search current word",
      },
    },
  },
}
