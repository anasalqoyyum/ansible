return {
  {
    "alex35mil/pi.nvim",
    enabled = false,
    lazy = true,
    opts = {
      models = "gpt-5.5",
      expand_startup_details = false,
      layout = {
        default = "float",
      },
    },
    keys = {
      {
        "<Leader>pp",
        function()
          vim.cmd("Pi layout=float")
        end,
        mode = { "n", "v" },
        desc = "Pi",
      },
      {
        "<Leader>ps",
        function()
          vim.cmd("Pi layout=side")
        end,
        mode = { "n", "v" },
        desc = "Pi side",
      },
      {
        "<Leader>pc",
        "<Cmd>PiContinue<CR>",
        mode = { "n", "v" },
        desc = "Pi continue last session",
      },
      {
        "<Leader>pr",
        "<Cmd>PiResume<CR>",
        mode = { "n", "v" },
        desc = "Pi resume past session",
      },
      {
        "<Leader>pm",
        "<Cmd>PiSendMention<CR>",
        mode = { "n", "v" },
        desc = "Pi mention file/selection",
      },
      {
        "<Leader>pa",
        "<Cmd>PiAttention<CR>",
        mode = { "n", "v" },
        desc = "Pi open next attention request",
      },
    },
  },
}
