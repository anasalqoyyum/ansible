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
    enabled = false,
    opts = {
      highlights = {
        DiagnosticUnderlineError = { undercurl = true },
        DiagnosticUnderlineWarn = { undercurl = true },
        DiagnosticUnderlineInfo = { undercurl = true },
        DiagnosticUnderlineHint = { undercurl = true },
      },
      options = {
        transparency = vim.g.theme_transparency,
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
      transparent = vim.g.theme_transparency,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  {
    "vague2k/vague.nvim",
    enabled = false,
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other plugins
    opts = {
      transparent = vim.g.theme_transparency, -- enable transparency
      italic = false,
      on_highlights = function(hl, c)
        hl.SnacksIndentScope = { fg = c.string }
      end,
    },
  },

  {
    "rose-pine/neovim",
    enabled = false,
    name = "rose-pine",
    opts = {
      styles = {
        bold = true,
        italic = false,
        transparency = vim.g.theme_transparency,
      },
    },
  },
}
