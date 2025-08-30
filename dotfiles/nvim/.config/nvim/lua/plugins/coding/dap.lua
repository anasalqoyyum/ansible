-- core plugin is pulled from lazy.extras.dap
return {
  {
    "rcarriga/nvim-dap-ui",
    opts = {
      layouts = {
        {
          elements = {
            "scopes",
            "breakpoints",
            "stacks",
            "watches",
          },
          size = 60, -- width of the sidebar
          position = "right", -- "left" | "right" | "top" | "bottom"
        },
        {
          elements = {
            "repl",
            "console",
          },
          size = 10, -- height of the bottom panel
          position = "bottom",
        },
      },
    },
  },
}
