return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
  },

  -- add and setup onedark theme
  {
    "olimorris/onedarkpro.nvim",
    lazy = true,
    enabled = false,
    opts = {
      highlights = {
        DiagnosticUnderlineError = { undercurl = true },
        DiagnosticUnderlineWarn = { undercurl = true },
        DiagnosticUnderlineInfo = { undercurl = true },
        DiagnosticUnderlineHint = { undercurl = true },
      },
      options = {
        transparency = true,
      },
    },
  },

  {
    "catppuccin/nvim",
    enabled = false,
  },

  {
    "folke/tokyonight.nvim",
    opts = {
      transparent = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },
}
