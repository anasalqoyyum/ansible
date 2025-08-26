return {
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight-night",
    },
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
    "vague2k/vague.nvim",
    enabled = false,
    opts = {
      transparent = vim.g.theme_transparency,
      -- this is fixing the indentscope not highlighted
      on_highlights = function(hl, c)
        hl.SnacksIndentScope = { fg = c.special }
      end,
      style = {
        strings = "none",
      },
    },
  },

  {
    "rose-pine/neovim",
    enabled = false,
    name = "rose-pine",
    opts = {
      styles = {
        transparency = vim.g.theme_transparency,
      },
      -- kinda hate italic on variable (confuses me)
      highlight_groups = {
        String = { italic = false },
        ["@variable"] = { italic = false },
        ["@variable.builtin"] = { italic = false },
        ["@variable.parameter"] = { italic = false },
        ["@variable.parameter.builtin"] = { italic = false },
        ["@parameter"] = { italic = false },
        ["@property"] = { italic = false },
      },
    },
  },
}
